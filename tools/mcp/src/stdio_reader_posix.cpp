// Reads a file descriptor line by line with poll(): nothing is read ahead of the line handed out (up to what one read()
// returned, which holds_input() reports), so a process that replaces itself with exec loses no message.
#include <cerrno>
#include <poll.h>
#include <unistd.h>

#include "fa/mcp/stdio.h"

namespace fa {

namespace {

class FdLineReader final : public LineReader {
public:
    explicit FdLineReader(int fd) : fd_(fd) {}

    Status next(std::string& line, std::chrono::milliseconds timeout) override {
        const auto deadline = std::chrono::steady_clock::now() + timeout;
        for (;;) {
            if (take_line(line)) return Status::Line;
            if (eof_) {
                if (buffer_.empty()) return Status::Eof;
                line = std::move(buffer_);  // the last line has no newline
                buffer_.clear();
                return Status::Line;
            }
            const auto left = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - std::chrono::steady_clock::now());
            if (left.count() < 0) return Status::Timeout;
            pollfd p{fd_, POLLIN, 0};
            const int ready = ::poll(&p, 1, int(left.count()));
            if (ready < 0) {
                if (errno == EINTR) continue;
                eof_ = true;
                continue;
            }
            if (ready == 0) return Status::Timeout;
            char chunk[65536];
            const ssize_t n = ::read(fd_, chunk, sizeof chunk);
            if (n > 0) buffer_.append(chunk, std::size_t(n));
            else if (n == 0 || errno != EINTR) eof_ = true;  // EOF, or a broken descriptor
        }
    }
    bool holds_input() const override { return !buffer_.empty(); }

private:
    bool take_line(std::string& line) {
        const std::size_t nl = buffer_.find('\n');
        if (nl == std::string::npos) return false;
        line.assign(buffer_, 0, nl);
        buffer_.erase(0, nl + 1);
        return true;
    }

    int fd_;
    std::string buffer_;
    bool eof_ = false;
};

}  // namespace

std::unique_ptr<LineReader> make_fd_reader(int fd) { return std::make_unique<FdLineReader>(fd); }
std::unique_ptr<LineReader> make_stdin_reader() { return make_fd_reader(0); }

}  // namespace fa
