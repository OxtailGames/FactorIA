#include "fa/runtime/input_recorder.h"

#include <cmath>

namespace fa {

void InputRecorder::start(std::uint64_t startFrame) {
    active_ = true;
    start_ = startFrame;
    frames_ = Json::object();
    timing_ = Json::array();
    date_.clear();
    time_.clear();
    utcOffsetMinutes_ = 0;
    keys_.clear();
    buttons_.clear();
    fingers_.clear();
    pads_ = {};
}

const char* InputRecorder::button_name(MouseButton b) {
    return b == MouseButton::Left ? "left" : b == MouseButton::Right ? "right" : "middle";
}

Json& InputRecorder::entry(std::uint64_t frame) { return frames_[std::to_string(frame >= start_ ? frame - start_ : 0)]; }

void InputRecorder::key(std::uint64_t frame, Key k, bool down) {
    if (k == Key::Unknown) return;
    if (down) keys_.insert(k); else keys_.erase(k);
    entry(frame)["keys"][key_name(k)] = down;
}

void InputRecorder::mouse_position(std::uint64_t frame, Vec2 p) { entry(frame)["mouse"]["position"] = Json::array({p.x, p.y}); }

void InputRecorder::mouse_button(std::uint64_t frame, MouseButton b, bool down) {
    if (down) buttons_.insert(b); else buttons_.erase(b);
    entry(frame)["mouse"][button_name(b)] = down;
}

void InputRecorder::pad_event(std::uint64_t frame, int index, const char* group, const char* name, Json value) {
    Json& list = entry(frame)["gamepad"];
    if (!list.is_array()) list = Json::array();
    const bool mergeable = std::string(group) != "connected";
    if (mergeable && !list.empty()) {
        Json& last = list.back();
        if (last["index"] == index && !last.contains("connected") && !(last.contains(group) && last[group].contains(name))) {
            last[group][name] = std::move(value);
            return;
        }
    }
    Json e = Json::object({{"index", index}});
    if (mergeable) e[group][name] = std::move(value);
    else e[group] = std::move(value);
    list.push_back(std::move(e));
}

void InputRecorder::gamepad_connected(std::uint64_t frame, int index, bool connected) {
    if (index < 0 || index >= kMaxGamepads) return;
    Pad& p = pads_[std::size_t(index)];
    if (p.connected == connected) return;
    p = Pad{};
    p.connected = connected;
    pad_event(frame, index, "connected", "", connected);
}

void InputRecorder::gamepad_button(std::uint64_t frame, int index, GamepadButton b, bool down) {
    if (index < 0 || index >= kMaxGamepads || std::size_t(b) >= std::size_t(GamepadButton::Count)) return;
    Pad& p = pads_[std::size_t(index)];
    if (p.buttons[std::size_t(b)] == down && p.connected) return;
    p.connected = true;
    p.buttons[std::size_t(b)] = down;
    pad_event(frame, index, "buttons", gamepad_button_name(b), down);
}

void InputRecorder::gamepad_axis(std::uint64_t frame, int index, GamepadAxis a, float value) {
    if (index < 0 || index >= kMaxGamepads || std::size_t(a) >= std::size_t(GamepadAxis::Count)) return;
    if (!(value == value)) value = 0.0f;
    Pad& p = pads_[std::size_t(index)];
    if (p.axes[std::size_t(a)] == value && p.connected) return;
    p.connected = true;
    p.axes[std::size_t(a)] = value;
    pad_event(frame, index, "axes", gamepad_axis_name(a), value);
}

void InputRecorder::touch_begin(std::uint64_t frame, std::uint64_t id, Vec2 p) {
    fingers_.insert(id);
    Json& list = entry(frame)["touch"];
    if (!list.is_array()) list = Json::array();
    list.push_back(Json::object({{"id", id}, {"position", Json::array({p.x, p.y})}, {"down", true}}));
}

void InputRecorder::touch_move(std::uint64_t frame, std::uint64_t id, Vec2 p) {
    if (!fingers_.count(id)) return;  // a move of a finger nobody put down does nothing: it must not begin one in the replay
    touch_begin(frame, id, p);        // "down" on a known id moves it
}

void InputRecorder::touch_end(std::uint64_t frame, std::uint64_t id) {
    if (!fingers_.erase(id)) return;
    Json& list = entry(frame)["touch"];
    if (!list.is_array()) list = Json::array();
    list.push_back(Json::object({{"id", id}, {"down", false}}));
}

void InputRecorder::back(std::uint64_t frame) { entry(frame)["back"] = true; }

void InputRecorder::clipboard(std::uint64_t frame, const std::string& text) {
    Json& e = entry(frame);
    if (!e.contains("clipboard")) e["clipboard"] = text;
}

void InputRecorder::release_all(std::uint64_t frame) {
    for (Key k : std::set<Key>(keys_)) key(frame, k, false);
    for (MouseButton b : std::set<MouseButton>(buttons_)) mouse_button(frame, b, false);
    for (std::uint64_t id : std::set<std::uint64_t>(fingers_)) touch_end(frame, id);
    for (int i = 0; i < kMaxGamepads; ++i) gamepad_connected(frame, i, false);
}

void InputRecorder::timing(std::uint64_t frameEnd, double dt, int steps, double fixedDt) {
    if (frameEnd <= start_) return;
    while (timing_.size() + 1 < frameEnd - start_) timing_.push_back(Json::array({fixedDt, 1}));
    if (timing_.size() + 1 == frameEnd - start_) timing_.push_back(Json::array({dt, steps}));
}

void InputRecorder::set_date(const std::string& iso, int utcOffsetMinutes, const std::string& time) {
    date_ = iso;
    time_ = time;
    utcOffsetMinutes_ = utcOffsetMinutes;
}

Json InputRecorder::input() const {
    Json j = Json::object({{"frames", frames_}, {"timing", timing_}});
    if (!date_.empty()) {
        j["date"] = date_;
        if (!time_.empty()) j["time"] = time_;
        j["utcOffsetMinutes"] = utcOffsetMinutes_;
    }
    return j;
}

void InputRecorder::observe_key(Key k, bool down) { if (active_) key(now(), k, down); }
void InputRecorder::observe_mouse_move(Vec2 p) { if (active_) mouse_position(now(), p); }
void InputRecorder::observe_mouse_button(MouseButton b, bool down) { if (active_) mouse_button(now(), b, down); }
void InputRecorder::observe_touch_begin(std::uint64_t id, Vec2 p) { if (active_) touch_begin(now(), id, p); }
void InputRecorder::observe_touch_move(std::uint64_t id, Vec2 p) { if (active_) touch_move(now(), id, p); }
void InputRecorder::observe_touch_end(std::uint64_t id) { if (active_) touch_end(now(), id); }
void InputRecorder::observe_gamepad_connected(int index, bool connected) { if (active_) gamepad_connected(now(), index, connected); }
void InputRecorder::observe_gamepad_button(int index, GamepadButton b, bool down) { if (active_) gamepad_button(now(), index, b, down); }
void InputRecorder::observe_gamepad_axis(int index, GamepadAxis a, float value) { if (active_) gamepad_axis(now(), index, a, value); }
void InputRecorder::observe_back() { if (active_) back(now()); }
void InputRecorder::observe_release_all() { if (active_) release_all(now()); }
void InputRecorder::clipboard_read(const std::string& text) { if (active_) clipboard(now(), text); }

}  // namespace fa
