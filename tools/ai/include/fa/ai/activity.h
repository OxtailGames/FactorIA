// "Is the agent still working?" for the editor's AI panel: the watchdog warning and its "Check activity" button.
// Pure logic and plain data (no UI, no threads), so it is tested without a window; the editor gathers the inputs.
#pragma once

#include <deque>
#include <string>
#include <vector>

#include "fa/core/process.h"

namespace fa::ai {

// CPU use of a set of processes between samples. add() takes the processes listed now (process_tree() of every tracked
// agent process); percent() compares the newest sample with the oldest one that is still inside the window. A process
// that appears between two samples counts with all its CPU time (it started inside the window); one that vanishes counts
// for nothing. cpuSeconds -1 (the OS did not say) is ignored.
class CpuSampler {
public:
    explicit CpuSampler(double windowSeconds = 120) : window_(windowSeconds) {}
    void add(double nowSeconds, const std::vector<ProcessEntry>& processes);
    // CPU use of the whole set over the window in percent of ONE core (150 = one and a half cores), or -1 when there are
    // fewer than two samples at least minSpanSeconds apart or the OS gave no CPU times.
    double percent(double minSpanSeconds = 3) const;
    // Seconds between the oldest and the newest sample (0 with fewer than two).
    double span() const;
    void clear() { samples_.clear(); }

private:
    struct Sample {
        double at = 0;
        std::vector<std::pair<long long, double>> cpu;  // pid -> CPU seconds
        bool known = false;                             // at least one process reported its CPU time
    };
    double window_;
    std::deque<Sample> samples_;
};

// Files of the project changed within the last `withinSeconds` (the agent writing scripts and scenes). Skips .git,
// .factoria, node_modules and build folders. Gives up after maxVisited entries or maxMillis: `complete` is then false.
struct RecentChanges {
    int count = 0;
    double newestAgoSeconds = -1;  // age of the newest change, -1 = none
    std::string newest;            // its path relative to the project
    bool complete = true;
};
RecentChanges recent_file_changes(const std::string& projectDir, double withinSeconds, int maxVisited = 20000, int maxMillis = 150);

struct ActivityInput {
    double runSeconds = 0;        // since the run started
    double idleSeconds = 0;       // since the last event of the agent
    std::string lastEvent;        // describe_agent_event() of the last event ("" = none yet)
    std::string tool;             // the tool call in flight ("running Bash (cmake --build build)"), "" = none
    double toolSeconds = 0;       // how long it has been in flight
    bool trackedProcess = false;  // a CLI agent process is known (an API provider has none)
    std::vector<ProcessEntry> processes;  // those processes and everything they started, now (empty = all gone)
    int roots = 0;                // how many tracked agent processes there are (the rest of `processes` are their children)
    double cpuPercent = -1;       // CpuSampler::percent(), -1 = unknown
    double cpuWindowSeconds = 0;  // what that percentage was measured over
    RecentChanges changes;        // project files changed lately, newest first
    double changesWithinSeconds = 0;
};

struct ActivityVerdict {
    bool stuck = false;       // "looks stuck": the panel keeps the warning and suggests Stop
    bool processGone = false; // the agent's process no longer exists
    std::string summary;      // one sentence: "Still working: ..." / "Looks stuck: ..." / "The agent process is gone ..."
    std::vector<std::string> details;  // one line each: process, CPU, children, tool, files, last event
};

// "4 min", "35 s", "1 h 05 min".
std::string format_duration(double seconds);

// The plain verdict of a check. Rules, in order: the process is gone -> gone; CPU use of 1% or more, a tool call that
// started less than a minute ago, or project files changed in the last two minutes -> still working; a child process
// beside the agent's own while a tool is in flight -> still working (it is that tool's program); otherwise stuck. With
// no process to inspect (API provider, or the OS told nothing) the verdict only says what was last seen.
ActivityVerdict judge_activity(const ActivityInput& in);

}  // namespace fa::ai
