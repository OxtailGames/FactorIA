// process_tree() on Windows: a Toolhelp snapshot gives the parent links, GetProcessTimes the CPU time.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <tlhelp32.h>

#include <algorithm>
#include <string>
#include <vector>

#include "fa/core/process.h"

namespace fa {

namespace {

std::string narrow(const wchar_t* w) {
    const int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 1) return {};
    std::string s(static_cast<std::size_t>(n - 1), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, s.data(), n, nullptr, nullptr);
    return s;
}

double cpu_seconds_of(DWORD pid) {
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!h) return -1;
    FILETIME created, exited, kernel, user;
    double seconds = -1;
    if (GetProcessTimes(h, &created, &exited, &kernel, &user)) {
        auto to_100ns = [](const FILETIME& f) {
            return (static_cast<unsigned long long>(f.dwHighDateTime) << 32) | f.dwLowDateTime;
        };
        seconds = static_cast<double>(to_100ns(kernel) + to_100ns(user)) / 1e7;
    }
    CloseHandle(h);
    return seconds;
}

}  // namespace

bool process_alive(long long pid) {
    if (pid <= 0) return false;
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, static_cast<DWORD>(pid));
    if (!h) return GetLastError() == ERROR_ACCESS_DENIED;  // denied = it exists; invalid parameter = no such process
    DWORD code = 0;
    const bool alive = GetExitCodeProcess(h, &code) && code == STILL_ACTIVE;
    CloseHandle(h);
    return alive;
}

std::vector<ProcessEntry> process_tree(long long rootPid) {
    std::vector<ProcessEntry> out;
    if (rootPid <= 0) return out;
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return out;
    std::vector<ProcessEntry> all;
    PROCESSENTRY32W e{};
    e.dwSize = sizeof e;
    for (BOOL ok = Process32FirstW(snap, &e); ok; ok = Process32NextW(snap, &e)) {
        ProcessEntry p;
        p.pid = e.th32ProcessID;
        p.parentPid = e.th32ParentProcessID;
        p.name = narrow(e.szExeFile);
        all.push_back(std::move(p));
    }
    CloseHandle(snap);
    auto root = std::find_if(all.begin(), all.end(), [&](const ProcessEntry& p) { return p.pid == rootPid; });
    if (root == all.end()) return out;
    out.push_back(*root);
    for (std::size_t i = 0; i < out.size(); ++i) {
        for (const ProcessEntry& p : all) {
            if (p.parentPid == out[i].pid && p.pid != rootPid && p.pid != 0 &&
                std::none_of(out.begin(), out.end(), [&](const ProcessEntry& o) { return o.pid == p.pid; }))
                out.push_back(p);
        }
    }
    for (ProcessEntry& p : out) p.cpuSeconds = cpu_seconds_of(static_cast<DWORD>(p.pid));
    // A process that has exited but is still referenced by a handle stays in the snapshot: it is not "alive".
    if (HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, static_cast<DWORD>(rootPid))) {
        DWORD code = 0;
        const bool exited = GetExitCodeProcess(h, &code) && code != STILL_ACTIVE;
        CloseHandle(h);
        if (exited) out.clear();
    }
    return out;
}

}  // namespace fa
