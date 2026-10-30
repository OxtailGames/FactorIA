// POSIX ChildProcess: fork/exec with three pipes, poll-based line reads, process-group kill.
// iOS, Android and the web build this file but start() always fails there (as run_process does).
#include "fa/core/child_process.h"

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

#if defined(__ANDROID__) || defined(__EMSCRIPTEN__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
#define FA_PROCESS_UNAVAILABLE 1
#endif

#ifdef FA_PROCESS_UNAVAILABLE

namespace fa {

struct ChildProcess::Impl {};
ChildProcess::ChildProcess() = default;
ChildProcess::~ChildProcess() = default;
Result<std::unique_ptr<ChildProcess>> ChildProcess::start(const ChildOptions& opt) {
    const std::string program = opt.argv.empty() ? std::string("a program") : "'" + opt.argv[0] + "'";
    return make_error("Cannot start " + program + ": running other programs is not available on iOS, Android and the web",
                      "Local tool servers (stdio) run on the desktop: use Windows, macOS or Linux.");
}
bool ChildProcess::write(std::string_view) { return false; }
ChildProcess::Read ChildProcess::read_line(std::string&, double, const CancelFlag*) { return Read::Closed; }
bool ChildProcess::running() { return false; }
void ChildProcess::terminate() {}
std::string ChildProcess::stderr_tail() const { return {}; }

}  // namespace fa

#else  // desktop POSIX: macOS and Linux

#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstring>
#include <mutex>

#include <fcntl.h>
#include <poll.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

namespace fa {

namespace {

double now_seconds() {
    using namespace std::chrono;
    return duration<double>(steady_clock::now().time_since_epoch()).count();
}

void set_cloexec(int fd) { fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) | FD_CLOEXEC); }

constexpr std::size_t kStderrTail = 8192;

}  // namespace

struct ChildProcess::Impl {
    pid_t pid = -1;
    int inFd = -1, outFd = -1, errFd = -1;
    std::string outBuf;
    mutable std::mutex errMu;
    std::string errTail;
    bool reaped = false;
    int status = 0;

    void add_stderr(const char* data, std::size_t n) {
        std::lock_guard<std::mutex> lk(errMu);
        errTail.append(data, n);
        if (errTail.size() > kStderrTail) errTail.erase(0, errTail.size() - kStderrTail);
    }
    bool reap(bool block) {
        if (reaped) return true;
        pid_t w;
        do { w = waitpid(pid, &status, block ? 0 : WNOHANG); } while (w < 0 && errno == EINTR);
        if (w == pid || (w < 0 && errno == ECHILD)) reaped = true;
        return reaped;
    }
    void close_all() {
        for (int* fd : {&inFd, &outFd, &errFd})
            if (*fd >= 0) { close(*fd); *fd = -1; }
    }
    void kill_group(int sig) {
        if (pid <= 0) return;
        kill(-pid, sig);
        kill(pid, sig);
    }
};

ChildProcess::ChildProcess() : impl_(std::make_unique<Impl>()) {}

ChildProcess::~ChildProcess() {
    if (!impl_ || impl_->pid <= 0) return;
    if (impl_->inFd >= 0) { close(impl_->inFd); impl_->inFd = -1; }  // a well-behaved server exits on end of input
    double until = now_seconds() + 0.5;
    while (!impl_->reap(false) && now_seconds() < until) usleep(5000);
    if (!impl_->reaped) {
        impl_->kill_group(SIGTERM);
        until = now_seconds() + 1.0;
        while (!impl_->reap(false) && now_seconds() < until) usleep(5000);
    }
    if (!impl_->reaped) {
        impl_->kill_group(SIGKILL);
        impl_->reap(true);
    } else {
        kill(-impl_->pid, SIGKILL);  // anything the program started and left behind
    }
    impl_->close_all();
}

Result<std::unique_ptr<ChildProcess>> ChildProcess::start(const ChildOptions& opt) {
    if (opt.argv.empty()) return make_error("ChildProcess: empty argv", "Pass at least the executable name.");
    static std::once_flag sigpipe;
    std::call_once(sigpipe, [] { std::signal(SIGPIPE, SIG_IGN); });  // a write to an exited child returns an error instead

    std::vector<char*> argv;
    for (const auto& a : opt.argv) argv.push_back(const_cast<char*>(a.c_str()));
    argv.push_back(nullptr);

    std::vector<std::string> envStore;
    for (char** e = environ; e && *e; ++e) {
        std::string s = *e;
        std::string key = s.substr(0, s.find('='));
        bool drop = opt.env.count(key) > 0;
        for (const auto& u : opt.unsetEnv) drop = drop || (u == key);
        if (!drop) envStore.push_back(std::move(s));
    }
    for (const auto& [k, v] : opt.env) envStore.push_back(k + "=" + v);
    std::vector<char*> envp;
    for (auto& s : envStore) envp.push_back(s.data());
    envp.push_back(nullptr);

    int inPipe[2], outPipe[2], errPipe[2], execPipe[2];
    auto close_pair = [](int* p) { close(p[0]); close(p[1]); };
    if (pipe(inPipe) != 0) return make_error(std::string("pipe failed: ") + std::strerror(errno));
    if (pipe(outPipe) != 0) { close_pair(inPipe); return make_error(std::string("pipe failed: ") + std::strerror(errno)); }
    if (pipe(errPipe) != 0) {
        close_pair(inPipe); close_pair(outPipe);
        return make_error(std::string("pipe failed: ") + std::strerror(errno));
    }
    if (pipe(execPipe) != 0) {
        close_pair(inPipe); close_pair(outPipe); close_pair(errPipe);
        return make_error(std::string("pipe failed: ") + std::strerror(errno));
    }
    set_cloexec(execPipe[0]); set_cloexec(execPipe[1]);
    set_cloexec(inPipe[1]); set_cloexec(outPipe[0]); set_cloexec(errPipe[0]);

    const char* cwd = opt.workingDir.empty() ? nullptr : opt.workingDir.c_str();
    const bool hasSlash = opt.argv[0].find('/') != std::string::npos;

    pid_t pid = fork();
    if (pid < 0) {
        int e = errno;
        close_pair(inPipe); close_pair(outPipe); close_pair(errPipe); close_pair(execPipe);
        return make_error(std::string("fork failed: ") + std::strerror(e));
    }
    if (pid == 0) {
        setpgid(0, 0);
        dup2(inPipe[0], 0);
        dup2(outPipe[1], 1);
        dup2(errPipe[1], 2);
        for (int fd : {inPipe[0], outPipe[1], errPipe[1]})
            if (fd > 2) close(fd);
        if (cwd && chdir(cwd) != 0) {
            int e = errno;
            ssize_t w = ::write(execPipe[1], &e, sizeof e); (void)w;
            _exit(127);
        }
        environ = envp.data();
        if (hasSlash) execv(argv[0], argv.data());
        else execvp(argv[0], argv.data());
        int e = errno;
        ssize_t w = ::write(execPipe[1], &e, sizeof e); (void)w;
        _exit(127);
    }
    setpgid(pid, pid);
    close(inPipe[0]); close(outPipe[1]); close(errPipe[1]); close(execPipe[1]);

    int execErr = 0;
    ssize_t r;
    do { r = read(execPipe[0], &execErr, sizeof execErr); } while (r < 0 && errno == EINTR);
    close(execPipe[0]);
    if (r == static_cast<ssize_t>(sizeof execErr)) {
        close(inPipe[1]); close(outPipe[0]); close(errPipe[0]);
        int st = 0;
        waitpid(pid, &st, 0);
        return make_error("Cannot start '" + opt.argv[0] + "': " + std::strerror(execErr),
                          execErr == ENOENT ? "Is it installed and on PATH? Check the working directory exists."
                                            : "Check file permissions.");
    }

    std::unique_ptr<ChildProcess> child(new ChildProcess());
    child->impl_->pid = pid;
    child->impl_->inFd = inPipe[1];
    child->impl_->outFd = outPipe[0];
    child->impl_->errFd = errPipe[0];
    return child;
}

bool ChildProcess::write(std::string_view data) {
    auto& d = *impl_;
    if (d.inFd < 0) return false;
    std::size_t off = 0;
    while (off < data.size()) {
        ssize_t w = ::write(d.inFd, data.data() + off, data.size() - off);
        if (w < 0) {
            if (errno == EINTR) continue;
            return false;
        }
        off += static_cast<std::size_t>(w);
    }
    return true;
}

ChildProcess::Read ChildProcess::read_line(std::string& line, double timeoutSeconds, const CancelFlag* cancel) {
    auto& d = *impl_;
    const double start = now_seconds();
    char buf[8192];
    for (;;) {
        auto nl = d.outBuf.find('\n');
        if (nl != std::string::npos) {
            std::size_t end = nl;
            if (end > 0 && d.outBuf[end - 1] == '\r') --end;
            line.assign(d.outBuf, 0, end);
            d.outBuf.erase(0, nl + 1);
            return Read::Line;
        }
        if (d.outFd < 0) {
            if (!d.outBuf.empty()) { line = std::move(d.outBuf); d.outBuf.clear(); return Read::Line; }
            // The output ended: the program is exiting. Give it a moment to be reaped so running() agrees with Closed.
            const double until = now_seconds() + 0.5;
            while (!d.reap(false) && now_seconds() < until) usleep(2000);
            return Read::Closed;
        }
        if (is_cancelled(cancel)) return Read::Cancelled;
        if (timeoutSeconds > 0 && now_seconds() - start > timeoutSeconds) return Read::Timeout;
        pollfd fds[2];
        int n = 0, idxErr = -1;
        fds[n++] = {d.outFd, POLLIN, 0};
        if (d.errFd >= 0) { idxErr = n; fds[n++] = {d.errFd, POLLIN, 0}; }
        int pr = poll(fds, static_cast<nfds_t>(n), 50);
        if (pr < 0) {
            if (errno == EINTR) continue;
            return Read::Closed;
        }
        if (idxErr >= 0 && (fds[idxErr].revents & (POLLIN | POLLHUP | POLLERR))) {
            ssize_t e = ::read(d.errFd, buf, sizeof buf);
            if (e > 0) d.add_stderr(buf, static_cast<std::size_t>(e));
            else if (e == 0 || errno != EINTR) { close(d.errFd); d.errFd = -1; }
        }
        if (fds[0].revents & (POLLIN | POLLHUP | POLLERR)) {
            ssize_t g = ::read(d.outFd, buf, sizeof buf);
            if (g > 0) d.outBuf.append(buf, static_cast<std::size_t>(g));
            else if (g == 0 || errno != EINTR) { close(d.outFd); d.outFd = -1; }
        }
    }
}

bool ChildProcess::running() {
    auto& d = *impl_;
    if (d.pid <= 0 || d.reaped) return false;
    return !d.reap(false);
}

void ChildProcess::terminate() {
    auto& d = *impl_;
    if (d.pid <= 0 || d.reaped) return;
    d.kill_group(SIGTERM);
    double until = now_seconds() + 1.0;
    while (!d.reap(false) && now_seconds() < until) usleep(5000);
    if (!d.reaped) { d.kill_group(SIGKILL); d.reap(true); }
    else kill(-d.pid, SIGKILL);
}

std::string ChildProcess::stderr_tail() const {
    std::lock_guard<std::mutex> lk(impl_->errMu);
    return impl_->errTail;
}

}  // namespace fa

#endif  // FA_PROCESS_UNAVAILABLE
