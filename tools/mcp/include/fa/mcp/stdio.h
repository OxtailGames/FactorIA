// The stdio loop of `factoria mcp`, with a clock: it wakes up when no message arrives, so that the server can notice by itself
// that it is out of date (fa/mcp/update_monitor.h) and hot-reload scripts, and can leave the loop for an in-place restart.
// run_stdio() (transport.h) is the plain loop that tests and embedders use.
#pragma once

#include <chrono>
#include <functional>
#include <iosfwd>
#include <memory>
#include <string>

#include "fa/mcp/server.h"

namespace fa {

// Hands out the lines of an input stream, waiting at most a given time for the next one.
class LineReader {
public:
    enum class Status { Line, Timeout, Eof };
    virtual ~LineReader() = default;
    // Waits up to `timeout` for a line (without its newline). A last line that ends without a newline is a Line too.
    virtual Status next(std::string& line, std::chrono::milliseconds timeout) = 0;
    // True when input was taken from the source and not yet handed out. A process that replaces itself would lose it, so it
    // waits until this is false (what the client wrote after that stays in the pipe, which the new process inherits).
    virtual bool holds_input() const = 0;
};

// stdin of the process. POSIX: file descriptor 0 read directly (poll + read), so nothing is read ahead of the lines
// handed out and `holds_input()` is exact. Elsewhere: a thread reading std::cin.
std::unique_ptr<LineReader> make_stdin_reader();
// A thread reading `in` line by line (any platform). The stream must outlive the reader; the destructor waits for the
// thread, which ends at the end of the stream, so close or exhaust it first.
std::unique_ptr<LineReader> make_stream_reader(std::istream& in);
#if !defined(_WIN32)
// Reads file descriptor `fd` (a pipe, in tests); the descriptor stays open and is the caller's.
std::unique_ptr<LineReader> make_fd_reader(int fd);
#endif

struct StdioLoopOptions {
    // Called before and after every message and whenever `idle` passes without one: hot reload, update checks.
    std::function<void()> poll;
    // Called instead of `poll` before a message is handled, when set: the message may need what a file the client wrote
    // just before it (a new tool) changed, so this check must not wait for a timer.
    std::function<void()> before_message;
    std::chrono::milliseconds idle{250};
    // Asked when the server is idle (no message being handled, no input held back): true leaves the loop with
    // StdioExit::Restart, right after the answer to the last message was written.
    std::function<bool()> restart_due;
};
enum class StdioExit { Eof, Restart };

// Reads messages from `reader`, answers on `out` (flushed per message; notifications of the server and of other threads
// share the writer). Returns at the end of the input, or when `restart_due` says so; the notification sink is cleared on return.
StdioExit run_stdio_loop(McpServer& server, LineReader& reader, std::ostream& out, const StdioLoopOptions& options = {});

}  // namespace fa
