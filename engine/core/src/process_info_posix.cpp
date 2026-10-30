// process_tree() for macOS and Linux (and Android, which has /proc); iOS and the web cannot ask, so they get an empty
// answer.
#include <signal.h>

#include <algorithm>
#include <cerrno>
#include <map>
#include <string>
#include <vector>

#include "fa/core/process.h"

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

#if defined(__linux__) || defined(__ANDROID__)
#define FA_PROCESS_INFO_PROC 1
#elif defined(__APPLE__) && !TARGET_OS_IPHONE
#define FA_PROCESS_INFO_LIBPROC 1
#endif

#if defined(FA_PROCESS_INFO_PROC)
#include <dirent.h>
#include <unistd.h>

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#elif defined(FA_PROCESS_INFO_LIBPROC)
#include <libproc.h>
#include <mach/mach_time.h>
#include <sys/proc_info.h>
#endif

namespace fa {

namespace {

// Every live process of the user as (pid, parent, name, cpu) in one list; zombies are left out.
std::vector<ProcessEntry> list_processes() {
    std::vector<ProcessEntry> all;
#if defined(FA_PROCESS_INFO_PROC)
    const double ticks = static_cast<double>(sysconf(_SC_CLK_TCK) > 0 ? sysconf(_SC_CLK_TCK) : 100);
    DIR* dir = opendir("/proc");
    if (!dir) return all;
    while (const dirent* e = readdir(dir)) {
        char* end = nullptr;
        const long long pid = std::strtoll(e->d_name, &end, 10);
        if (!end || *end != '\0' || pid <= 0) continue;
        std::ifstream in("/proc/" + std::string(e->d_name) + "/stat");
        std::string line;
        if (!in || !std::getline(in, line)) continue;
        // "pid (comm) S ppid pgrp session tty tpgid flags minflt cminflt majflt cmajflt utime stime ...": comm may
        // hold spaces and parentheses, so parse after the last ')'.
        const std::size_t open = line.find('('), close = line.rfind(')');
        if (open == std::string::npos || close == std::string::npos || close < open) continue;
        std::istringstream rest(line.substr(close + 1));
        std::string state;
        long long ppid = 0, skip = 0;
        unsigned long long utime = 0, stime = 0;
        rest >> state >> ppid;
        for (int i = 0; i < 9; ++i) rest >> skip;  // pgrp .. cmajflt
        rest >> utime >> stime;
        if (!rest || state == "Z" || state == "X") continue;
        ProcessEntry p;
        p.pid = pid;
        p.parentPid = ppid;
        p.name = line.substr(open + 1, close - open - 1);
        p.cpuSeconds = static_cast<double>(utime + stime) / ticks;
        all.push_back(std::move(p));
    }
    closedir(dir);
#elif defined(FA_PROCESS_INFO_LIBPROC)
    // proc_listallpids returns a COUNT of pids (not bytes, unlike proc_listpids); the buffer is given in bytes. Processes
    // start between the two calls, so it has headroom and is asked again when it came back full.
    std::vector<int> pids;
    int got = 0;
    for (int attempt = 0; attempt < 4; ++attempt) {
        const int count = proc_listallpids(nullptr, 0);
        if (count <= 0) return all;
        pids.assign(static_cast<std::size_t>(count) + static_cast<std::size_t>(count) / 4 + 64 + 64u * attempt, 0);
        got = proc_listallpids(pids.data(), static_cast<int>(pids.size() * sizeof(int)));
        if (got <= 0) return all;
        if (static_cast<std::size_t>(got) < pids.size()) break;  // room to spare: that was every pid
    }
    pids.resize(static_cast<std::size_t>(got));
    mach_timebase_info_data_t tb{1, 1};
    mach_timebase_info(&tb);
    for (int pid : pids) {
        if (pid <= 0) continue;
        proc_bsdinfo bsd{};
        if (proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsd, sizeof bsd) != static_cast<int>(sizeof bsd)) continue;
        if (bsd.pbi_status == 5) continue;  // SZOMB (<sys/proc.h> is not for user code)
        ProcessEntry p;
        p.pid = pid;
        p.parentPid = bsd.pbi_ppid;
        p.name = bsd.pbi_name[0] ? bsd.pbi_name : bsd.pbi_comm;
        proc_taskinfo ti{};
        if (proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &ti, sizeof ti) == static_cast<int>(sizeof ti)) {
            const double ns = static_cast<double>(ti.pti_total_user + ti.pti_total_system) * tb.numer / tb.denom;
            p.cpuSeconds = ns / 1e9;
        }
        all.push_back(std::move(p));
    }
#endif
    return all;
}

}  // namespace

bool process_alive(long long pid) {
    if (pid <= 0) return false;
#if defined(FA_PROCESS_INFO_PROC) || defined(FA_PROCESS_INFO_LIBPROC)
    if (kill(static_cast<pid_t>(pid), 0) == 0) {
        // A zombie (exited, awaiting its parent) still answers kill(): it is not alive.
        for (const ProcessEntry& p : list_processes())
            if (p.pid == pid) return true;
        return false;
    }
    return errno == EPERM;  // ESRCH = no such process; EPERM = it exists but belongs to someone else
#else
    return false;
#endif
}

std::vector<ProcessEntry> process_tree(long long rootPid) {
    std::vector<ProcessEntry> out;
    if (rootPid <= 0) return out;
    const std::vector<ProcessEntry> all = list_processes();
    auto root = std::find_if(all.begin(), all.end(), [&](const ProcessEntry& p) { return p.pid == rootPid; });
    if (root == all.end()) return out;
    out.push_back(*root);
    // Breadth first over the parent links (the list is small: a few hundred processes).
    for (std::size_t i = 0; i < out.size(); ++i) {
        for (const ProcessEntry& p : all) {
            if (p.parentPid == out[i].pid && p.pid != rootPid &&
                std::none_of(out.begin(), out.end(), [&](const ProcessEntry& o) { return o.pid == p.pid; }))
                out.push_back(p);
        }
    }
    return out;
}

}  // namespace fa
