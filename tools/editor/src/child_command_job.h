// One command of the open project run in a child `factoria` process on a worker thread, so the editor's UI thread never waits for
// it: `factoria call --project DIR --no-graphics --json <command> <args>`. The Level generator's "Sheet of N seeds" runs review.sheet
// this way (generating N levels takes seconds, and review.sheet sets the process-wide project root while it works, so it cannot run
// on a worker thread of the editor itself). Cancel kills the child's process tree. Plain logic: no ImGui, no Editor (tests call it).
#pragma once

#include <atomic>
#include <chrono>
#include <filesystem>
#include <mutex>
#include <optional>
#include <string>
#include <thread>

#include "fa/core/json.h"
#include "fa/core/process.h"

namespace fa::editor {

struct ChildCommandOutcome {
    bool ok = false;
    bool cancelled = false;
    Json value;                   // the command's result when ok
    std::string error, hint;      // when not ok (and not cancelled)
    double seconds = 0;           // real time the child took
};
// Reads what `factoria call --json <command>` printed (a command error is {"ok":false,"error":{...}}).
ChildCommandOutcome child_command_outcome(const ProcessResult& run, const std::string& stdoutText, const std::string& command);

class ChildCommandJob {
public:
    ChildCommandJob() = default;
    ChildCommandJob(const ChildCommandJob&) = delete;
    ChildCommandJob& operator=(const ChildCommandJob&) = delete;
    ~ChildCommandJob() {
        cancel();
        wait();
    }

    // Starts the command; false while one runs. A missing factoria executable is not a failed start: the outcome says so.
    // `timeoutSeconds` is a safety net far above a normal run (the command's own work caps decide what it does).
    bool start(const std::filesystem::path& projectDir, const std::string& command, const Json& args, double timeoutSeconds);
    bool running() const { return running_.load(); }
    void cancel() { cancel_.store(true); }
    double elapsed_seconds() const;
    const std::string& command() const { return command_; }
    std::optional<ChildCommandOutcome> take_result();   // once, when finished
    void wait();

private:
    std::thread thread_;
    std::atomic<bool> running_{false};
    CancelFlag cancel_{false};
    mutable std::mutex mu_;
    std::optional<ChildCommandOutcome> result_;
    std::string command_;
    std::chrono::steady_clock::time_point started_;
};

}  // namespace fa::editor
