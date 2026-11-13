// What a window host does with its first frames (docs/ARCHITECTURE.md, "Start-up order"):
//
//   frame 1   present a clear frame (the window shows black instead of nothing), record WindowReady and FirstPresent
//   frame 2   read the game: Engine::init (scenes, scripts, textures, shaders) - the slow part - then present a clear frame
//   frames 3+ make the GPU pipelines the first scene draws with, a slice (as many pipeline groups as fit in ~8 ms) per frame, each frame presenting a clear frame
//   then      the game runs, one game frame per window frame
//
// The window system presents when a frame callback returns, so a frame cannot be shown from inside the init callback: that is why
// the first frame is its own frame. The sequence only decides WHAT each window frame does; the hooks do it. Nothing the game
// simulates or draws depends on it: the first game frame is the same frame 0 of the game with or without it.
#pragma once

#include <functional>

#include "fa/core/startup.h"

namespace fa {

class StartupSequence {
public:
    struct Hooks {
        std::function<void()> present_clear;  // present one cleared frame (Renderer::present_clear)
        std::function<bool()> init;           // read the game (Engine::init); false = it could not start
        std::function<int()> warm;  // one slice of GPU warm-up (several groups); returns the groups left (0 = done)
    };
    enum class State { FirstFrame, Init, Warm, Running, Failed };

    // `timeline` gets WindowReady and FirstPresent from here; it may be null.
    StartupSequence(Hooks hooks, StartupTimeline* timeline) : hooks_(std::move(hooks)), timeline_(timeline) {}

    // Call once at the start of every window frame. Returns true when this frame is a GAME frame (the host runs it now); false
    // when the sequence used the frame itself (a clear frame was presented, or the start failed: see failed()).
    bool on_frame();

    State state() const { return state_; }
    bool failed() const { return state_ == State::Failed; }
    bool running() const { return state_ == State::Running; }

private:
    Hooks hooks_;
    StartupTimeline* timeline_;
    State state_ = State::FirstFrame;
};

}  // namespace fa
