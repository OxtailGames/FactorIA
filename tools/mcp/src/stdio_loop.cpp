#include <condition_variable>
#include <deque>
#include <istream>
#include <mutex>
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
    auto restart_due = [&] { return options.restart_due && !reader.holds_input() && options.restart_due(); };
    StdioExit exit = StdioExit::Eof;
    std::string line;
    for (;;) {
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
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.find_first_not_of(" \t") == std::string::npos) continue;
        poll();
        if (auto response = server.handle_message(line)) write(*response);
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
