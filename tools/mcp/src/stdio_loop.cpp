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

// The id of a single request the server will begin (McpServer::handle_one: JSON-RPC 2.0, a string method other than
// initialize, a string or number id); null for anything else (a notification, a response, a batch, garbage).
Json queued_request_id(const std::string& line) {
    if (line.find("\"id\"") == std::string::npos) return nullptr;  // cheap test first: most notifications stop here
    Json msg = Json::parse(line, nullptr, false);
    if (!msg.is_object() || !msg.contains("jsonrpc") || msg["jsonrpc"] != "2.0") return nullptr;
    if (!msg.contains("method") || !msg["method"].is_string() || msg["method"] == "initialize") return nullptr;
    if (!msg.contains("id") || !(msg["id"].is_string() || msg["id"].is_number())) return nullptr;
    return msg["id"];
}

// Reads the input on its own thread for the whole loop, so a notifications/cancelled reaches the server at once, whether
// the request it names runs (it stops) or still waits behind another one in `lines_` (it is skipped:
// McpSession::expect_request). Every other line waits in `lines_` for its turn. stop() joins the thread, so the loop can
// look at the reader's held input without a read in progress.
class Inbox {
public:
    static constexpr std::chrono::milliseconds kRead{50};  // how often the thread looks at `stop_`

    Inbox(McpServer& server, LineReader& reader) : server_(server), reader_(reader) { start(); }
    ~Inbox() { stop(); }
    Inbox(const Inbox&) = delete;
    Inbox& operator=(const Inbox&) = delete;

    void start() {
        std::lock_guard<std::mutex> lock(mu_);
        if (eof_ || thread_.joinable()) return;
        stop_ = false;
        thread_ = std::thread([this] { run(); });
    }
    void stop() {
        {
            std::lock_guard<std::mutex> lock(mu_);
            stop_ = true;
        }
        if (thread_.joinable()) thread_.join();
    }
    enum class Got { Line, Timeout, Eof };
    Got next(std::string& line, std::chrono::milliseconds timeout) {
        std::unique_lock<std::mutex> lock(mu_);
        cv_.wait_for(lock, timeout, [this] { return !lines_.empty() || eof_; });
        if (!lines_.empty()) {
            line = std::move(lines_.front());
            lines_.pop_front();
            return Got::Line;
        }
        return eof_ ? Got::Eof : Got::Timeout;
    }
    bool empty() const {
        std::lock_guard<std::mutex> lock(mu_);
        return lines_.empty();
    }

private:
    void run() {
        std::string line;
        for (;;) {
            {
                std::lock_guard<std::mutex> lock(mu_);
                if (stop_) return;
            }
            const LineReader::Status status = reader_.next(line, kRead);
            if (status == LineReader::Status::Timeout) continue;
            if (status == LineReader::Status::Eof) {
                std::lock_guard<std::mutex> lock(mu_);
                eof_ = true;
                cv_.notify_all();
                return;
            }
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.find_first_not_of(" \t") == std::string::npos) continue;
            if (McpServer::is_cancel_notification(line)) {
                server_.handle_message(line);  // only touches the session: thread-safe
                continue;
            }
            // Announced before it is queued: a cancel read after this line finds it.
            const Json id = queued_request_id(line);
            if (!id.is_null()) server_.session()->expect_request(id);
            std::lock_guard<std::mutex> lock(mu_);
            lines_.push_back(std::move(line));
            cv_.notify_all();
        }
    }

    McpServer& server_;
    LineReader& reader_;
    mutable std::mutex mu_;
    std::condition_variable cv_;
    std::deque<std::string> lines_;
    bool eof_ = false;
    bool stop_ = false;
    std::thread thread_;
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
    Inbox inbox(server, reader);
    // A restart loses nothing: no line waits in the inbox and, with the reading thread stopped, the reader holds no input
    // (what the client writes later stays in the pipe for the next process). Otherwise reading goes on.
    auto restart_now = [&] {
        if (!options.restart_due || !inbox.empty() || !options.restart_due()) return false;
        inbox.stop();
        if (inbox.empty() && !reader.holds_input()) return true;
        inbox.start();
        return false;
    };
    StdioExit exit = StdioExit::Eof;
    std::string line;
    for (;;) {
        const Inbox::Got got = inbox.next(line, options.idle);
        if (got == Inbox::Got::Eof) break;
        if (got == Inbox::Got::Timeout) {
            poll();
            if (restart_now()) {
                exit = StdioExit::Restart;
                break;
            }
            continue;
        }
        if (options.before_message) options.before_message();
        else poll();
        if (auto response = server.handle_message(line)) write(*response);
        poll();
        if (restart_now()) {
            exit = StdioExit::Restart;
            break;
        }
    }
    inbox.stop();
    server.set_notification_sink(nullptr);
    return exit;
}

}  // namespace fa
