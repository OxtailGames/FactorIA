// A one-way channel from the process that runs ai.run to the terminal that started `factoria ai run`.
//
// `factoria ai run` runs a CLI orchestrator (Claude Code), which starts its own `factoria mcp` server process; the
// orchestrator's ai_run calls (the sub-agents) run THERE, not in the terminal's process, so their events cannot reach the
// terminal through a callback. The server appends one line per step of a sub-agent to <project>/.factoria/ai/progress.log;
// the terminal tails that file while its run lasts and prints the lines. Best effort: a line that cannot be written is lost.
#pragma once

#include <atomic>
#include <functional>
#include <string>
#include <thread>

namespace fa::ai {

// <projectDir>/.factoria/ai/progress.log
std::string progress_file_path(const std::string& projectDir);

// Appends `line` (one line; newlines are replaced by spaces) to the project's progress file, creating it and its folder.
void append_progress_line(const std::string& projectDir, const std::string& line);

// Calls onLine (on a thread of its own) for every line appended to the progress file after construction. The destructor
// reads once more, then joins: lines written before it ran are delivered.
class ProgressTail {
public:
    ProgressTail(const std::string& projectDir, std::function<void(const std::string& line)> onLine,
                 int pollMillis = 250);
    ~ProgressTail();
    ProgressTail(const ProgressTail&) = delete;
    ProgressTail& operator=(const ProgressTail&) = delete;

private:
    void poll();
    std::string path_;
    std::function<void(const std::string&)> onLine_;
    int pollMillis_;
    std::uintmax_t offset_ = 0;
    std::string partial_;  // the last, unfinished line
    std::atomic<bool> stop_{false};
    std::thread thread_;
};

}  // namespace fa::ai
