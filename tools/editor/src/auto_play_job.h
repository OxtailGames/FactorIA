// Play > Let the AI Play: runs the play.auto command for the open project without freezing the window.
//
// The editor already holds the graphics device, so the bot plays in a child process (`factoria call --project DIR
// --no-graphics --json play.auto ...`, the same thing the command does itself when it finds the device busy), started on a worker
// thread so the UI thread only polls. Cancel kills the child's process tree; the session is written by the child only when its run
// ends, so a cancelled run leaves nothing behind. Everything here is plain logic: no ImGui, no Editor, no window. The session
// list (play_sessions_model.h) and the window (play_sessions_panel.cpp) use it, and tests call it directly.
#pragma once

#include <atomic>
#include <chrono>
#include <deque>
#include <filesystem>
#include <mutex>
#include <optional>
#include <string>
#include <thread>

#include "fa/core/json.h"
#include "fa/core/process.h"

namespace fa::editor {

// What the window asks of the bot. `seconds` is GAME time (the real time is a fraction of it: the bot plays fast).
struct AutoPlayRequest {
    std::filesystem::path projectDir;  // the open project's folder (a path object: the child gets it as UTF-8)
    double seconds = 60;
    bool screenshots = true;  // a picture per phase, per problem and at the end (needs a graphics device in the child)
};
inline constexpr double kAutoPlayMinSeconds = 5;
inline constexpr double kAutoPlayMaxSeconds = 600;  // the window's own limit; play.auto itself takes up to 3600
inline constexpr double kAutoPlayDefaultSeconds = 60;

// The play.auto arguments of a request (seconds clamped to the window's range).
Json auto_play_args(const AutoPlayRequest& request);

// The factoria executable that runs the child: $FA_FACTORIA_EXE when set (tests, a build tree where the editor and the command
// line tool are not side by side), the running executable when it is `factoria` (the editor is `factoria editor`), or the
// `factoria` next to it. "" when none is found.
std::string auto_play_executable();

// One run's result, as the window and the toast show it.
struct AutoPlayOutcome {
    bool ok = false;
    bool cancelled = false;  // the user pressed Cancel: the child was stopped and no session was written
    std::string session;     // folder name under .factoria/sessions/ ("" when not ok)
    std::string ended;       // won | lost | timeout | stuck | broken | quit | aborted
    std::string endedWhy;
    int problems = 0;  // the marks the bot made
    int phases = 0;
    std::string error, hint;  // when not ok (and not cancelled): what went wrong and how to fix it
    double seconds = 0;       // real time the run took
};
// Reads what `factoria call --json play.auto` printed (a command error is {"ok":false,"error":{...}}).
AutoPlayOutcome auto_play_outcome(const ProcessResult& run, const std::string& stdoutText);
// One line for the toast and the log: "The AI played 60 s of game time in 4 s: it ended `timeout`, 0 problems." / the error.
std::string auto_play_summary(const AutoPlayOutcome& outcome);

class AutoPlayJob {
public:
    AutoPlayJob() = default;
    AutoPlayJob(const AutoPlayJob&) = delete;
    AutoPlayJob& operator=(const AutoPlayJob&) = delete;
    ~AutoPlayJob() {
        cancel();
        wait();
    }

    // Starts a run; false while one is going. A missing factoria executable is not a failed start: the outcome says so.
    bool start(const AutoPlayRequest& request);
    bool running() const { return running_.load(); }
    void cancel() { cancel_.store(true); }
    bool cancelling() const { return running() && cancel_.load(); }
    double elapsed_seconds() const;                              // real time since the run started (0 when none runs)
    std::string progress_line() const;                           // the child's latest log line ("" = none yet)
    const AutoPlayRequest& request() const { return request_; }  // of the running or last run
    std::optional<AutoPlayOutcome> take_result();  // the finished run's outcome, once; nullopt while it runs
    bool has_result() const {                      // a run ended and take_result() has not collected it yet
        std::lock_guard lock(mu_);
        return result_.has_value();
    }
    void wait();  // blocks until the run is done (the child is killed first by cancel())

private:
    std::thread thread_;
    std::atomic<bool> running_{false};
    CancelFlag cancel_{false};
    mutable std::mutex mu_;
    std::optional<AutoPlayOutcome> result_;
    std::string line_;
    AutoPlayRequest request_;
    std::chrono::steady_clock::time_point started_;
};

}  // namespace fa::editor
