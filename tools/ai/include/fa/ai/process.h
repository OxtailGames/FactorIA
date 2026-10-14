// Cross-platform child-process runner (POSIX: fork/exec in process_posix.cpp,
// Windows: CreateProcess in process_win32.cpp) used by CLI agents, `which`,
// version probes and the curl-executable HTTP fallback.
#pragma once

#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/types.h"

namespace fa::ai {

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
// bad working dir...). A non-zero exit code is a successful Result.
Result<ProcessResult> run_process(const ProcessOptions& options);

// Absolute path of an executable found in PATH (PATHEXT on Windows), or "".
std::string which(std::string_view name);

}  // namespace fa::ai
