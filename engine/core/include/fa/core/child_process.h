// A child program kept alive with its standard input and output connected, for line-based protocols (the stdio transport of
// MCP tool servers speaks one JSON message per line). run_process (process.h) runs a program to its end and cannot be
// written to while it runs; this class can.
//
// POSIX in child_process_posix.cpp, Windows in child_process_win32.cpp. Like run_process, start() fails on iOS, Android and
// the web. One thread at a time may use an object (the caller serializes requests).
#pragma once

#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/process.h"

namespace fa {

struct ChildOptions {
    std::vector<std::string> argv;            // argv[0] is looked up in PATH if it has no separator
    std::string workingDir;                   // empty = inherit
    std::map<std::string, std::string> env;   // overrides added to the inherited environment
    std::vector<std::string> unsetEnv;
};

class ChildProcess {
public:
    enum class Read { Line, Timeout, Closed, Cancelled };

    // Starts the program. Fails (Error with a hint) when it cannot be started. Its standard error is collected
    // (stderr_tail()), never mixed into the lines read.
    static Result<std::unique_ptr<ChildProcess>> start(const ChildOptions& options);
    ~ChildProcess();  // closes its input, gives it a moment to leave, then kills it and everything it started
    ChildProcess(const ChildProcess&) = delete;
    ChildProcess& operator=(const ChildProcess&) = delete;

    // Writes all of `data` to the child's standard input. False when the child is gone.
    bool write(std::string_view data);
    // Reads one line of the child's standard output ('\n' or '\r\n' stripped) into `line`. Timeout: nothing complete arrived
    // within timeoutSeconds (0 = wait for ever). Closed: the child's output ended (it exited). Cancelled: `cancel` was set.
    Read read_line(std::string& line, double timeoutSeconds, const CancelFlag* cancel = nullptr);
    bool running();          // false once the program has exited
    void terminate();        // kills it and everything it started (idempotent)
    std::string stderr_tail() const;  // the last few KB the program wrote to its standard error

    struct Impl;

private:
    ChildProcess();
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
