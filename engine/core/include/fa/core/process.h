// Cross-platform child-process runner (POSIX: fork/exec in process_posix.cpp, Windows: CreateProcess in
// process_win32.cpp) used by CLI agents, `which`, version probes, the curl-executable HTTP fallback and the export
// tooling (Gradle, keytool...).
//
// Starting programs is not available on iOS and Android (the OS forbids it or it is not wanted there): `run_process`
// compiles everywhere, so the runtime links, but returns an Error on those platforms. `which` works everywhere.
#pragma once

#include <atomic>
#include <cstddef>
#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// Cooperative cancellation: callers set it to true; long operations poll it.
using CancelFlag = std::atomic<bool>;
inline bool is_cancelled(const CancelFlag* f) { return f && f->load(std::memory_order_relaxed); }

struct ProcessOptions {
    std::vector<std::string> argv;               // argv[0] is looked up in PATH if it has no separator
    std::string workingDir;                      // empty = inherit
    std::map<std::string, std::string> env;      // overrides added to the inherited environment
    std::vector<std::string> unsetEnv;           // variables removed from the child environment
    std::string stdinText;                       // the child's standard input (empty = no input)
    std::function<void(std::string_view line)> onStdoutLine;   // complete lines, '\n'/'\r\n' stripped
    std::function<void(std::string_view chunk)> onStdoutChunk; // raw bytes as they arrive (optional)
    std::function<void(std::string_view line)> onStderrLine;   // optional
    const CancelFlag* cancel = nullptr;          // set to true => child tree is killed
    double timeoutSeconds = 0;                   // 0 = none
    // Called once, on the calling thread, right after the program started, with its process id (process_tree()).
    std::function<void(long long pid)> onStart;
    // Return when the program itself exits, even if a descendant it started still holds its output pipes (a background
    // job, a daemon): the pipes are given 2 s to run dry, then the rest of its process group is killed. Without it
    // run_process waits for the pipes to close, which for such a descendant is forever. Windows always behaves so
    // (its job object kills the descendants).
    bool endWithChild = false;
    bool captureStdout = true;                   // keep stdout in ProcessResult (capped at maxCapture)
    std::size_t maxCapture = 8u << 20;
};

struct ProcessResult {
    int exitCode = -1;       // -1 when killed / not exited normally
    bool cancelled = false;
    bool timedOut = false;
    std::string stdoutText;  // if captureStdout
    std::string stderrText;  // always captured (capped)
};

// Fails (Error) only when the process could not be started (missing executable,
// bad working dir...). A non-zero exit code is a successful Result. Always fails on iOS and Android.
Result<ProcessResult> run_process(const ProcessOptions& options);

// One process of a tree, as process_tree() reports it.
struct ProcessEntry {
    long long pid = 0;
    long long parentPid = 0;
    std::string name;         // the program's name ("claude", "cmake"), as short as the OS gives it
    double cpuSeconds = -1;   // user + system CPU time used so far; -1 = the OS did not tell
};

// The process `rootPid` and every process it started that still lives, the root first. Empty when the root is gone
// (or has exited and only awaits its parent: a zombie), or where the OS offers no way to ask (iOS, the web). Reads only
// what the OS lists for the user's own processes: it never fails, an unreadable entry just has cpuSeconds -1. Meant for
// "is it still working" checks: call it twice and compare cpuSeconds for the CPU use in between.
std::vector<ProcessEntry> process_tree(long long rootPid);

// Absolute path of an executable found in PATH (PATHEXT on Windows), or "".
std::string which(std::string_view name);

}  // namespace fa
