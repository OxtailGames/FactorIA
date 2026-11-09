#include <chrono>
#include <condition_variable>
#include <deque>
#include <istream>
#include <mutex>
#include <optional>
#include <ostream>
#include <thread>

#include "fa/mcp/stdio.h"

namespace fa {

namespace {

// A thread reads the stream line by line into a queue; next() waits on it with a timeout.
class StreamLineReader final : public LineReader {
public:
    explicit StreamLineReader(std::istream& in) : thread_([this, &in] {
        std::string line;
        while (std::getline(in, line)) {
            std::lock_guard<std::mutex> lock(mu_);
            lines_.push_back(line);
            cv_.notify_all();
        }
        std::lock_guard<std::mutex> lock(mu_);
        eof_ = true;
        cv_.notify_all();
    }) {}
    ~StreamLineReader() override { thread_.join(); }

    Status next(std::string& line, std::chrono::milliseconds timeout) override {
        std::unique_lock<std::mutex> lock(mu_);
        cv_.wait_for(lock, timeout, [this] { return !lines_.empty() || eof_; });
        if (!lines_.empty()) {
            line = std::move(lines_.front());
            lines_.pop_front();
            return Status::Line;
        }
        return eof_ ? Status::Eof : Status::Timeout;
    }
    bool holds_input() const override {
        std::lock_guard<std::mutex> lock(mu_);
        return !lines_.empty();
    }

private:
    mutable std::mutex mu_;
    std::condition_variable cv_;
    std::deque<std::string> lines_;
    bool eof_ = false;
    std::thread thread_;  // last: starts when everything above exists
};

}  // namespace

std::unique_ptr<LineReader> make_stream_reader(std::istream& in) { return std::make_unique<StreamLineReader>(in); }

namespace {

// While a message is handled (on the loop's thread: `factoria mcp` runs commands where its GL context is), the input is
// still read: a notifications/cancelled goes to the server at once, which stops the request that runs (MCP
// "Cancellation"); every other line waits in `deferred` for its turn. The watcher starts reading only after `kGrace`, so
// that a quick request (most are) ends without waiting for a read that has to time out.
class CancelWatcher {
public:
    static constexpr std::chrono::milliseconds kGrace{200};
    static constexpr std::chrono::milliseconds kRead{50};  // how long the loop waits for the watcher at the end

    CancelWatcher(McpServer& server, LineReader& reader, std::deque<std::string>& deferred, bool& eof)
        : server_(server), reader_(reader), deferred_(deferred), eof_(eof), thread_([this] { run(); }) {}
    ~CancelWatcher() {
        {
            std::lock_guard<std::mutex> lock(mu_);
            done_ = true;
        }
        cv_.notify_all();
        thread_.join();  // `deferred` and `eof` are the loop's again
    }
    CancelWatcher(const CancelWatcher&) = delete;
    CancelWatcher& operator=(const CancelWatcher&) = delete;

private:
    void run() {
        {
            std::unique_lock<std::mutex> lock(mu_);
            if (cv_.wait_for(lock, kGrace, [this] { return done_; })) return;
        }
        std::string line;
        for (;;) {
            {
                std::lock_guard<std::mutex> lock(mu_);
                if (done_) return;
            }
            const LineReader::Status status = reader_.next(line, kRead);
            if (status == LineReader::Status::Eof) {
                eof_ = true;  // the loop reads it after the join
                return;
            }
            if (status == LineReader::Status::Timeout) continue;
            if (McpServer::is_cancel_notification(line)) server_.handle_message(line);  // only touches the session: thread-safe
            else deferred_.push_back(std::move(line));
        }
    }

    McpServer& server_;
    LineReader& reader_;
    std::deque<std::string>& deferred_;
    bool& eof_;
    std::mutex mu_;
    std::condition_variable cv_;
    bool done_ = false;
    std::thread thread_;  // last: starts when everything above exists
};

}  // namespace

StdioExit run_stdio_loop(McpServer& server, LineReader& reader, std::ostream& out, const StdioLoopOptions& options) {
    // Responses and asynchronous notifications (other threads) share one writer.
    std::mutex writeMutex;
    auto write = [&](const std::string& line) {
        std::lock_guard<std::mutex> lock(writeMutex);
        out << line << '\n';
        out.flush();
    };
    server.set_notification_sink(write);
    auto poll = [&] {
        if (options.poll) options.poll();
    };
    std::deque<std::string> deferred;  // lines read while a message was handled, in order
    bool eof = false;                  // the watcher saw the end of the input
    auto restart_due = [&] {
        return options.restart_due && deferred.empty() && !reader.holds_input() && options.restart_due();
    };
    StdioExit exit = StdioExit::Eof;
    std::string line;
    for (;;) {
        if (!deferred.empty()) {
            line = std::move(deferred.front());
            deferred.pop_front();
        } else {
            if (eof) break;
            const LineReader::Status status = reader.next(line, options.idle);
            if (status == LineReader::Status::Eof) break;
            if (status == LineReader::Status::Timeout) {
                poll();
                if (restart_due()) {
                    exit = StdioExit::Restart;
                    break;
                }
                continue;
            }
        }
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.find_first_not_of(" \t") == std::string::npos) continue;
        if (options.before_message) options.before_message();
        else poll();
        std::optional<std::string> response;
        {
            CancelWatcher watcher(server, reader, deferred, eof);
            response = server.handle_message(line);
        }
        if (response) write(*response);
        poll();
        if (restart_due()) {
            exit = StdioExit::Restart;
            break;
        }
    }
    server.set_notification_sink(nullptr);
    return exit;
}

}  // namespace fa
