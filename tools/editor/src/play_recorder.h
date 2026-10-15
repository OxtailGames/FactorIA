// Records the input the editor feeds the game while it plays, in the input replay format
// (`factoria run --headless --input`): {"frames": {"<n>": {"keys": {"Space": true}, "mouse": {...}}}}.
// Frame numbers are relative to the start of the session; an entry is applied BEFORE that frame runs, which is what
// the events received between two frames mean. Each frame's dt and fixed-step count go to "timing": [[dt, steps], ...],
// so the headless replay runs the same frames (exact even when the editor ran slower or faster than the fixed rate).
// No ImGui, no Editor: tests feed it directly.
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
        timing_ = Json::array();
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
    // After the engine ran up to frame `frameEnd` (exclusive): the last frame took `dt` and ran `steps` fixed steps.
    // Frames before it that were not reported were engine.step(1) calls (Step button, game.step): [fixedDt, 1].
    void timing(std::uint64_t frameEnd, double dt, int steps, double fixedDt) {
        if (frameEnd <= start_) return;
        while (timing_.size() + 1 < frameEnd - start_) timing_.push_back(Json::array({fixedDt, 1}));
        if (timing_.size() + 1 == frameEnd - start_) timing_.push_back(Json::array({dt, steps}));
    }
    Json input() const { return Json::object({{"frames", frames_}, {"timing", timing_}}); }

private:
    static const char* button_name(MouseButton b) { return b == MouseButton::Left ? "left" : b == MouseButton::Right ? "right" : "middle"; }
    Json& entry(std::uint64_t frame) { return frames_[std::to_string(frame >= start_ ? frame - start_ : 0)]; }

    std::uint64_t start_ = 0;
    Json frames_ = Json::object();
    Json timing_ = Json::array();
    std::set<Key> keys_;
    std::set<MouseButton> buttons_;
};

}  // namespace fa::editor
