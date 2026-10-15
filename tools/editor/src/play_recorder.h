// Records the input the editor feeds the game while it plays, in the input replay format
// (`factoria run --headless --input`): {"frames": {"<n>": {"keys": {"Space": true}, "mouse": {...}}}}.
// Frame numbers are relative to the start of the session; an entry is applied BEFORE that frame runs, which is what
// the events received between two frames mean. No ImGui, no Editor: tests feed it directly.
// Not recorded (the replay format has no field for them): mouse wheel, typed text. The editor feeds no gamepad or touch.
#pragma once

#include <cstdint>
#include <set>
#include <string>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/platform/input.h"

namespace fa::editor {

class PlayRecorder {
public:
    void start(std::uint64_t startFrame) {
        start_ = startFrame;
        frames_ = Json::object();
        keys_.clear();
        buttons_.clear();
    }
    void key(std::uint64_t frame, Key k, bool down) {
        if (k == Key::Unknown) return;
        if (down) keys_.insert(k); else keys_.erase(k);
        entry(frame)["keys"][key_name(k)] = down;
    }
    void mouse_position(std::uint64_t frame, Vec2 p) { entry(frame)["mouse"]["position"] = Json::array({p.x, p.y}); }
    void mouse_button(std::uint64_t frame, MouseButton b, bool down) {
        if (down) buttons_.insert(b); else buttons_.erase(b);
        entry(frame)["mouse"][button_name(b)] = down;
    }
    // Everything held is let go (the editor does this on Pause / focus loss, the engine does the same to its input).
    void release_all(std::uint64_t frame) {
        for (Key k : std::set<Key>(keys_)) key(frame, k, false);
        for (MouseButton b : std::set<MouseButton>(buttons_)) mouse_button(frame, b, false);
    }
    Json input() const { return Json::object({{"frames", frames_}}); }

private:
    static const char* button_name(MouseButton b) { return b == MouseButton::Left ? "left" : b == MouseButton::Right ? "right" : "middle"; }
    Json& entry(std::uint64_t frame) { return frames_[std::to_string(frame >= start_ ? frame - start_ : 0)]; }

    std::uint64_t start_ = 0;
    Json frames_ = Json::object();
    std::set<Key> keys_;
    std::set<MouseButton> buttons_;
};

}  // namespace fa::editor
