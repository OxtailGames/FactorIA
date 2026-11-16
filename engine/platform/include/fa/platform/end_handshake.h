// The end of an app whose engine runs on another thread than the one the operating system tells it on.
//
// Android: onDestroy arrives on the Java main thread, while the engine (and every script) lives on sokol_app's loop thread.
// The main thread asks with request(): it wakes the engine's thread and waits, at most `budget`, for that thread to run
// the game's last code (serve()). Script code never runs on the main thread, the work runs once whoever asks again, and
// an engine thread that is stuck (a quit handler that never returns, a long frame) holds the main thread for the budget
// only: Android kills an app whose main thread blocks for seconds. activity_end_android.cpp supplies the wake-up (a pipe
// the loop thread's ALooper watches); the class itself has no Android dependency, so every OS unit-tests it.
#pragma once

#include <chrono>
#include <condition_variable>
#include <functional>
#include <mutex>

namespace fa {

class EndHandshake {
public:
    enum class Outcome {
        Served,        // the engine's thread ran the work (during this wait, or before it was asked)
        TimedOut,      // the budget ran out first: the work may still be running, or may never run
        NotDelivered,  // wake() failed: nothing was asked of the engine's thread
    };

    // The thread the OS calls (Android's main thread). Returns at once with Served when the work already ran; otherwise
    // calls wake() (which must make the engine's thread call serve() soon, and return false when it could not) and waits
    // for the work to finish, at most `budget`. Several callers may wait at once.
    Outcome request(std::chrono::milliseconds budget, const std::function<bool()>& wake);

    // The engine's thread: runs `work` if it has not run yet, then answers every request() waiting. Later calls do
    // nothing and return false; true when this call ran it. An exception that leaves `work` is logged and swallowed (the
    // waiters are answered all the same).
    bool serve(const std::function<void()>& work);

    // True once the work finished.
    bool served() const;

private:
    enum class State { Idle, Running, Done };
    mutable std::mutex mutex_;
    std::condition_variable done_;
    State state_ = State::Idle;
};

}  // namespace fa
