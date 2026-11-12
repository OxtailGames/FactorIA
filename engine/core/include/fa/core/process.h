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
#include <optional>
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
    // Allow-list mode. nullopt (the default) = the child inherits the whole environment of this process. A list = only the
    // variables whose names match an entry are inherited (see env_name_matches: exact names, case-insensitive on Windows, a
    // trailing '*' makes a prefix: "LC_*"); `env` is added to them and `unsetEnv` still removes. Programs that run what an AI
    // wrote (hooks, agent CLIs) use base_child_env() so signing passwords and other providers' API keys stay out of their
    // reach.
    std::optional<std::vector<std::string>> inheritEnv;
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
    // POSIX: the program runs in a session of its own (setsid() after fork), so it has no controlling terminal: a program that
    // would ask /dev/tty for a password (xcrun notarytool) reads its standard input instead, and a background process cannot be
    // stopped for reading the terminal. Its process group is its own as always, so a cancel, a timeout or the end of
    // endWithChild still signal the whole tree (SIGTERM, SIGKILL after 2 s). Windows: does nothing (a child has no controlling
    // terminal there to begin with; its job object already ends the whole tree).
    bool newSession = false;
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

// Does environment variable `name` match `pattern`: the same name, or, when the pattern ends in '*', a name that starts with the
// rest of it ("LC_*" matches "LC_ALL"). `caseInsensitive` is how Windows compares variable names (ASCII letters only).
bool env_name_matches(std::string_view pattern, std::string_view name, bool caseInsensitive);

// The variables every child of a hook or an AI tool needs to work and that hold no secret: PATH, HOME/USER/LOGNAME/SHELL, the
// temp folder (TMPDIR, TEMP, TMP), the locale (LANG, LANGUAGE, LC_*), TERM, TZ, the few FACTORIA_*/FA_* variables a `factoria`
// started by them reads (FACTORIA_AI_CONFIG, FACTORIA_HOME, FACTORIA_ENGINE_DIR, FACTORIA_CALLER, FACTORIA_CAPABILITIES,
// FACTORIA_ROLE, FACTORIA_IN_HOOK, FA_CACHE_DIR, FA_LANGUAGE, FA_JOB_THREADS), the paths of the tools it finds by
// variable (SOKOL_SHDC, FACTORIA_EXPORT_CONFIG, FACTORIA_FFMPEG, FACTORIA_STEAMCMD, FACTORIA_FASTLANE, FACTORIA_XCRUN: paths, not
// secrets) and, on Windows, what cmd.exe, Node and the compilers need (SystemRoot, ComSpec, PATHEXT,
// USERPROFILE, APPDATA, LOCALAPPDATA, ProgramData, ProgramFiles*...). Never the signing passwords (FACTORIA_*_PASSWORD) nor API
// keys. Use it as ProcessOptions::inheritEnv / ChildOptions::inheritEnv, with `extra` names added: see child_env_allow.
const std::vector<std::string>& base_child_env();
// base_child_env() followed by `extra` (names or "PREFIX*" patterns), without repeating a name.
std::vector<std::string> child_env_allow(const std::vector<std::string>& extra);

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

// Asks the OS directly (kill(pid, 0) on POSIX, OpenProcess + GetExitCodeProcess on Windows) whether process `pid` still
// runs; a zombie or an exited process whose handle is still held is not alive. Unlike process_tree() it does not depend on
// a process list, so it settles "is it really gone" before anything is stopped for it. False where the OS offers no way to
// ask (iOS, the web).
bool process_alive(long long pid);

// Absolute path of an executable found in PATH (PATHEXT on Windows), or "".
std::string which(std::string_view name);

}  // namespace fa
