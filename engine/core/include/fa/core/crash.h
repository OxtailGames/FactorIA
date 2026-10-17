// Crash reports: when the process dies from a fault (null write, stack overflow, abort(), an uncaught exception...), a
// report is written into a folder before it ends, so a developer can see where it happened. The player installs this
// next to log.txt (docs/EXPORTING.md, "Crash reports").
//
//   <dir>/crash-<UTC>.txt   readable: engine + game, the signal or exception, the stack, the last log lines
//   <dir>/crash-<UTC>.dmp   Windows only: a minidump (Visual Studio or WinDbg opens it)
//
// Windows : SetUnhandledExceptionFilter (access violation, stack overflow, ...) plus the C runtime's abort / terminate /
//           invalid-parameter / pure-call paths. The report is written from a helper thread (a thread whose stack
//           overflowed has no room left); StackWalk64 + dbghelp name the frames (module+offset without symbols).
// POSIX   : sigaction on SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT and SIGTRAP, running on an alternate stack; only
//           async-signal-safe calls in the handler; backtrace() names the frames the dynamic symbol table knows
//           (module+offset otherwise: addr2line / atos). The default action runs afterwards, so the process still dies
//           with the signal. Linux and macOS.
// Android and iOS: not available (the OS keeps crash logs: tombstones / `adb logcat`, Xcode Organizer); installing
//           returns an Error there.
//
// Limits: a stack overflow is only reported on the thread that called install_crash_reporter (the main thread); a
// crash inside the allocator can stop the report half way (a watchdog ends the process after 15-30 seconds).
#pragma once

#include <cstddef>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa {

struct CrashReporterOptions {
    // The folder reports go into (created). Each crash writes crash-<UTC time>.txt (and .dmp on Windows).
    std::filesystem::path dir;
    // "key: value" lines copied under the engine line of every report, e.g. "game: Space Dodge 1.2.0". Prepared now,
    // because a crashing process cannot build strings.
    std::vector<std::string> info;
    // Newest reports kept in `dir`; older crash-*.txt / .dmp are deleted when the reporter is installed.
    std::size_t keep = 5;
};

// Installs the handlers for the whole process and keeps the last log lines for the reports (a log sink). Call it once,
// early, from the main thread; a second call only replaces `dir`, `info` and `keep`. Never call it from the editor or
// the `factoria` CLI. Fails (Error with a hint) when the folder cannot be created or on Android and iOS.
Result<void> install_crash_reporter(const CrashReporterOptions& options);

// The newest crash-*.txt in `dir` that this function has not returned before, else an empty path. A game calls it at
// start-up to tell "the previous run crashed" once, not on every later start (a `.reported` file in `dir` remembers).
std::filesystem::path take_previous_crash_report(const std::filesystem::path& dir);

}  // namespace fa
