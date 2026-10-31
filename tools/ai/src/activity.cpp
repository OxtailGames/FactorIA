#include "fa/ai/activity.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <filesystem>
#include <map>

namespace fa::ai {

void CpuSampler::add(double nowSeconds, const std::vector<ProcessEntry>& processes) {
    Sample s;
    s.at = nowSeconds;
    for (const ProcessEntry& p : processes) {
        if (p.cpuSeconds < 0) continue;
        s.cpu.emplace_back(p.pid, p.cpuSeconds);
        s.known = true;
    }
    samples_.push_back(std::move(s));
    while (samples_.size() > 2 && nowSeconds - samples_[1].at > window_) samples_.pop_front();
}

double CpuSampler::span() const {
    return samples_.size() < 2 ? 0 : samples_.back().at - samples_.front().at;
}

double CpuSampler::percent(double minSpanSeconds) const {
    if (samples_.size() < 2) return -1;
    const Sample& now = samples_.back();
    // The oldest sample inside the window (the deque is trimmed in add()) that is old enough to measure against.
    const Sample* from = nullptr;
    for (const Sample& s : samples_) {
        if (&s == &now) break;
        if (now.at - s.at >= minSpanSeconds) {
            from = &s;
            break;
        }
    }
    if (!from || !now.known) return -1;
    std::map<long long, double> before(from->cpu.begin(), from->cpu.end());
    double used = 0;
    for (const auto& [pid, cpu] : now.cpu) {
        auto it = before.find(pid);
        used += it == before.end() ? cpu : std::max(0.0, cpu - it->second);
    }
    return 100.0 * used / (now.at - from->at);
}

RecentChanges recent_file_changes(const std::string& projectDir, double withinSeconds, int maxVisited, int maxMillis) {
    namespace sfs = std::filesystem;
    RecentChanges out;
    std::error_code ec;
    const sfs::path root(projectDir);
    if (projectDir.empty() || !sfs::is_directory(root, ec)) return out;
    const auto started = std::chrono::steady_clock::now();
    const auto fileNow = sfs::file_time_type::clock::now();
    int visited = 0;
    sfs::recursive_directory_iterator it(root, sfs::directory_options::skip_permission_denied, ec), end;
    for (; !ec && it != end; it.increment(ec)) {
        const sfs::path& p = it->path();
        const std::string name = p.filename().string();
        std::error_code e2;
        if (it->is_directory(e2)) {
            if (name == ".git" || name == ".factoria" || name == "node_modules" || name == "build" || name == ".cache") it.disable_recursion_pending();
            continue;
        }
        if (++visited > maxVisited ||
            std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - started).count() > maxMillis) {
            out.complete = false;
            break;
        }
        const auto mtime = it->last_write_time(e2);
        if (e2) continue;
        const double age = std::chrono::duration<double>(fileNow - mtime).count();
        if (age < 0 || age > withinSeconds) continue;
        ++out.count;
        if (out.newestAgoSeconds < 0 || age < out.newestAgoSeconds) {
            out.newestAgoSeconds = age;
            out.newest = sfs::relative(p, root, e2).generic_string();
        }
    }
    return out;
}

std::string format_duration(double seconds) {
    const long long s = seconds < 0 ? 0 : static_cast<long long>(seconds + 0.5);
    char buf[48];
    if (s < 60) std::snprintf(buf, sizeof buf, "%lld s", s);
    else if (s < 3600) std::snprintf(buf, sizeof buf, "%lld min", s / 60);
    else std::snprintf(buf, sizeof buf, "%lld h %02lld min", s / 3600, (s % 3600) / 60);
    return buf;
}

static std::string cpu_text(double percent) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.0f%%", percent);
    return buf;
}

ActivityVerdict judge_activity(const ActivityInput& in) {
    ActivityVerdict v;
    const std::string idle = format_duration(in.idleSeconds);
    const int children = std::max(0, static_cast<int>(in.processes.size()) - in.roots);
    const bool cpuKnown = in.cpuPercent >= 0;
    const bool cpuBusy = cpuKnown && in.cpuPercent >= 1.0;
    const bool recentFiles = in.changes.count > 0;
    const bool freshTool = !in.tool.empty() && in.toolSeconds < 60;

    // Details: what the check saw, one line each.
    if (in.trackedProcess) {
        if (in.processes.empty()) {
            v.details.push_back("Process: gone.");
        } else {
            std::string names;
            for (std::size_t i = 0; i < in.processes.size() && i < 6; ++i) names += (i ? ", " : "") + in.processes[i].name;
            v.details.push_back("Process: alive (" + std::to_string(in.processes.size()) + " incl. children: " + names +
                                (in.processes.size() > 6 ? ", ..." : "") + ").");
        }
        v.details.push_back(cpuKnown ? "CPU: " + cpu_text(in.cpuPercent) + " over the last " + format_duration(in.cpuWindowSeconds) + "."
                                     : "CPU: not known (needs two samples, or this system does not report it).");
        if (!in.processes.empty()) v.details.push_back("Child processes: " + std::to_string(children) + ".");
    } else {
        v.details.push_back("Process: none to inspect (an API provider runs inside the editor).");
    }
    v.details.push_back(in.tool.empty() ? "Tool call in flight: none."
                                        : "Tool call in flight: " + in.tool + " for " + format_duration(in.toolSeconds) + ".");
    if (in.changes.count > 0)
        v.details.push_back("Project files changed in the last " + format_duration(in.changesWithinSeconds) + ": " +
                            std::to_string(in.changes.count) + (in.changes.complete ? "" : "+") + " (newest " + in.changes.newest + ", " +
                            format_duration(in.changes.newestAgoSeconds) + " ago).");
    else
        v.details.push_back("Project files changed in the last " + format_duration(in.changesWithinSeconds) + ": none" +
                            (in.changes.complete ? "." : " (scan cut short)."));
    v.details.push_back(in.lastEvent.empty() ? "Last event: none yet (" + idle + " ago)."
                                             : "Last event: " + in.lastEvent + ", " + idle + " ago.");

    const std::string doing = in.tool.empty() ? std::string("the agent") : in.tool;
    if (in.trackedProcess && in.processes.empty()) {
        v.processGone = true;
        v.stuck = true;
        v.summary = "The agent process is gone (last event " + idle + " ago): the run cannot go on. Press Stop.";
        return v;
    }
    if (!in.trackedProcess) {
        // Nothing to look at but the events: say what was seen, do not guess.
        v.summary = "Cannot look inside this agent (no process). Last event " + idle + " ago" +
                    (recentFiles ? "; project files are still changing, so it is probably working." : ". Press Stop if you do not want to wait.");
        v.stuck = !recentFiles && in.idleSeconds >= 600;
        return v;
    }
    const std::string cpu = cpuKnown ? ", CPU " + cpu_text(in.cpuPercent) : "";
    if (cpuBusy || freshTool || recentFiles || (!in.tool.empty() && children > 0)) {
        v.summary = "Still working: " + (in.tool.empty() ? std::string("the agent process is busy") : in.tool + " for " + format_duration(in.toolSeconds)) +
                    cpu + (children > 0 ? ", " + std::to_string(children) + " child process(es)" : "") +
                    (recentFiles && !cpuBusy ? ", project files changed lately" : "") + ".";
        return v;
    }
    v.stuck = true;
    v.summary = "Looks stuck: process alive but idle" + (cpuKnown ? " (" + cpu_text(in.cpuPercent) + " CPU)" : std::string()) + " for " + idle +
                (in.tool.empty() ? ", no tool in flight" : ", " + doing + " has been in flight for " + format_duration(in.toolSeconds)) +
                ". Waiting for a slow model reply looks the same: press Stop if you do not want to wait.";
    return v;
}

}  // namespace fa::ai
