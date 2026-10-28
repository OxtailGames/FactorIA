// POSIX process runner: fork/exec, pipes, poll loop, process-group kill.
//
// iOS and Android build this file too (the runtime links against fa_core there) but get a run_process that always
// fails: iOS forbids fork/exec for apps and the Android player has no use for starting programs.
#include "fa/core/process.h"

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

#if defined(__ANDROID__) || defined(__EMSCRIPTEN__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
#define FA_PROCESS_UNAVAILABLE 1
#endif

#ifdef FA_PROCESS_UNAVAILABLE

namespace fa {

Result<ProcessResult> run_process(const ProcessOptions& opt) {
    const std::string program = opt.argv.empty() ? std::string("a program") : "'" + opt.argv[0] + "'";
    return make_error("Cannot start " + program + ": running other programs is not available on iOS, Android and the web",
                      "Export, build and tool commands run on the desktop: use Windows, macOS or Linux.");
}

}  // namespace fa

#else  // desktop POSIX: macOS and Linux

#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstdio>
#include <cstring>

#include <fcntl.h>
#include <poll.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

namespace fa {

namespace {

struct LineSplitter {
    std::string buf;
    std::function<void(std::string_view)> cb;
    void feed(const char* data, std::size_t n) {
        buf.append(data, n);
        std::size_t start = 0;
        for (;;) {
            auto nl = buf.find('\n', start);
            if (nl == std::string::npos) break;
            std::size_t end = nl;
            if (end > start && buf[end - 1] == '\r') --end;
            if (cb) cb(std::string_view(buf).substr(start, end - start));
            start = nl + 1;
        }
        buf.erase(0, start);
    }
    void flush() {
        if (!buf.empty() && cb) cb(buf);
        buf.clear();
    }
};

double now_seconds() {
    using namespace std::chrono;
    return duration<double>(steady_clock::now().time_since_epoch()).count();
}

void set_cloexec(int fd) { fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) | FD_CLOEXEC); }

}  // namespace

Result<ProcessResult> run_process(const ProcessOptions& opt) {
    if (opt.argv.empty()) return make_error("run_process: empty argv", "Pass at least the executable name.");

    // Build argv / envp BEFORE fork (only async-signal-safe calls after it).
    std::vector<char*> argv;
    for (const auto& a : opt.argv) argv.push_back(const_cast<char*>(a.c_str()));
    argv.push_back(nullptr);

    std::vector<std::string> envStore;
    for (char** e = environ; e && *e; ++e) {
        std::string s = *e;
        auto eq = s.find('=');
        std::string key = s.substr(0, eq);
        bool drop = opt.env.count(key) > 0;
        for (const auto& u : opt.unsetEnv) drop = drop || (u == key);
        if (!drop) envStore.push_back(std::move(s));
    }
    for (const auto& [k, v] : opt.env) envStore.push_back(k + "=" + v);
    std::vector<char*> envp;
    for (auto& s : envStore) envp.push_back(s.data());
    envp.push_back(nullptr);

    int outPipe[2], errPipe[2], execPipe[2];
    if (pipe(outPipe) != 0) return make_error(std::string("pipe failed: ") + std::strerror(errno));
    if (pipe(errPipe) != 0) {
        close(outPipe[0]); close(outPipe[1]);
        return make_error(std::string("pipe failed: ") + std::strerror(errno));
    }
    if (pipe(execPipe) != 0) {
        close(outPipe[0]); close(outPipe[1]); close(errPipe[0]); close(errPipe[1]);
        return make_error(std::string("pipe failed: ") + std::strerror(errno));
    }
    set_cloexec(execPipe[1]);
    set_cloexec(outPipe[0]);
    set_cloexec(errPipe[0]);
    set_cloexec(execPipe[0]);

    // The child's standard input: /dev/null, or an anonymous temporary file holding stdinText, so there is no pipe to
    // keep writing while stdout is read.
    int inFd = -1;
    if (!opt.stdinText.empty()) {
        std::FILE* f = std::tmpfile();
        if (f && std::fwrite(opt.stdinText.data(), 1, opt.stdinText.size(), f) == opt.stdinText.size() &&
            std::fflush(f) == 0)
            inFd = dup(fileno(f));
        if (f) std::fclose(f);
        if (inFd < 0 || lseek(inFd, 0, SEEK_SET) != 0) {
            int e = errno;
            if (inFd >= 0) close(inFd);
            for (int fd : {outPipe[0], outPipe[1], errPipe[0], errPipe[1], execPipe[0], execPipe[1]}) close(fd);
            return make_error("Cannot write the standard input of '" + opt.argv[0] + "' to a temporary file: " +
                                  std::strerror(e),
                              "Check that /tmp exists and is writable.");
        }
        set_cloexec(inFd);
    }

    const char* cwd = opt.workingDir.empty() ? nullptr : opt.workingDir.c_str();
    const bool hasSlash = opt.argv[0].find('/') != std::string::npos;

    pid_t pid = fork();
    if (pid < 0) {
        int e = errno;
        close(outPipe[0]); close(outPipe[1]); close(errPipe[0]); close(errPipe[1]);
        close(execPipe[0]); close(execPipe[1]);
        if (inFd >= 0) close(inFd);
        return make_error(std::string("fork failed: ") + std::strerror(e));
    }
    if (pid == 0) {
        setpgid(0, 0);  // own process group so we can kill the whole tree
        if (inFd >= 0) dup2(inFd, 0);
        else {
            int devnull = open("/dev/null", O_RDONLY);
            if (devnull >= 0) { dup2(devnull, 0); if (devnull > 2) close(devnull); }
        }
        dup2(outPipe[1], 1);
        dup2(errPipe[1], 2);
        if (outPipe[1] > 2) close(outPipe[1]);
        if (errPipe[1] > 2) close(errPipe[1]);
        if (cwd && chdir(cwd) != 0) {
            int e = errno;
            ssize_t w = write(execPipe[1], &e, sizeof e); (void)w;
            _exit(127);
        }
        // execvpe is a GNU extension; emulate: search PATH of the *child* env is
        // unnecessary, so use the parent's PATH via execvp after setting environ.
        environ = envp.data();
        if (hasSlash) execv(argv[0], argv.data());
        else execvp(argv[0], argv.data());
        int e = errno;
        ssize_t w = write(execPipe[1], &e, sizeof e); (void)w;
        _exit(127);
    }
    // parent
    setpgid(pid, pid);
    if (inFd >= 0) close(inFd);
    close(outPipe[1]);
    close(errPipe[1]);
    close(execPipe[1]);

    int execErr = 0;
    {
        ssize_t r;
        do { r = read(execPipe[0], &execErr, sizeof execErr); } while (r < 0 && errno == EINTR);
        close(execPipe[0]);
        if (r == static_cast<ssize_t>(sizeof execErr)) {
            close(outPipe[0]); close(errPipe[0]);
            int st = 0;
            waitpid(pid, &st, 0);
            std::string msg = "Cannot start '" + opt.argv[0] + "': " + std::strerror(execErr);
            std::string hint = execErr == ENOENT
                ? (opt.workingDir.empty() ? "Is it installed and on PATH?" : "Check that it is on PATH and the working directory exists.")
                : "Check file permissions.";
            return make_error(msg, hint);
        }
    }

    if (opt.onStart) opt.onStart(static_cast<long long>(pid));

    ProcessResult res;
    LineSplitter outLines{{}, opt.onStdoutLine};
    LineSplitter errLines{{}, opt.onStderrLine};
    const double start = now_seconds();
    double killAt = -1;  // when to escalate to SIGKILL
    bool terminated = false;
    int outFd = outPipe[0], errFd = errPipe[0];
    char buf[8192];
    int status = 0;
    bool reaped = false;
    double exitedAt = -1;  // endWithChild: when the program was seen to have exited

    auto terminate = [&] {
        if (terminated) return;
        terminated = true;
        kill(-pid, SIGTERM);
        kill(pid, SIGTERM);
        killAt = now_seconds() + 2.0;
    };

    while (outFd >= 0 || errFd >= 0) {
        if (!terminated) {
            if (is_cancelled(opt.cancel)) { res.cancelled = true; terminate(); }
            else if (opt.timeoutSeconds > 0 && now_seconds() - start > opt.timeoutSeconds) {
                res.timedOut = true; terminate();
            }
        } else if (killAt > 0 && now_seconds() > killAt) {
            kill(-pid, SIGKILL);
            kill(pid, SIGKILL);
            killAt = -1;
            // Descendants holding the pipes open must not block us forever.
            if (outFd >= 0) { close(outFd); outFd = -1; }
            if (errFd >= 0) { close(errFd); errFd = -1; }
            break;
        }
        if (opt.endWithChild && !reaped) {
            if (waitpid(pid, &status, WNOHANG) == pid) {
                reaped = true;
                exitedAt = now_seconds();
            }
        }
        if (reaped && now_seconds() - exitedAt > 2.0) {
            // The program is gone but something it started still holds the pipes: stop waiting for them.
            kill(-pid, SIGKILL);
            if (outFd >= 0) { close(outFd); outFd = -1; }
            if (errFd >= 0) { close(errFd); errFd = -1; }
            break;
        }
        pollfd fds[2];
        int n = 0;
        int idxOut = -1, idxErr = -1;
        if (outFd >= 0) { idxOut = n; fds[n++] = {outFd, POLLIN, 0}; }
        if (errFd >= 0) { idxErr = n; fds[n++] = {errFd, POLLIN, 0}; }
        int pr = poll(fds, n, 50);
        if (pr < 0) {
            if (errno == EINTR) continue;
            break;
        }
        auto drain = [&](int& fd, bool isOut) {
            ssize_t r;
            do { r = read(fd, buf, sizeof buf); } while (r < 0 && errno == EINTR);
            if (r <= 0) { close(fd); fd = -1; return; }
            if (isOut) {
                if (opt.captureStdout && res.stdoutText.size() < opt.maxCapture)
                    res.stdoutText.append(buf, static_cast<std::size_t>(r));
                if (opt.onStdoutChunk) opt.onStdoutChunk(std::string_view(buf, static_cast<std::size_t>(r)));
                outLines.feed(buf, static_cast<std::size_t>(r));
            } else {
                if (res.stderrText.size() < opt.maxCapture) res.stderrText.append(buf, static_cast<std::size_t>(r));
                errLines.feed(buf, static_cast<std::size_t>(r));
            }
        };
        if (idxOut >= 0 && (fds[idxOut].revents & (POLLIN | POLLHUP | POLLERR))) drain(outFd, true);
        if (idxErr >= 0 && (fds[idxErr].revents & (POLLIN | POLLHUP | POLLERR))) drain(errFd, false);
    }
    if (outFd >= 0) close(outFd);
    if (errFd >= 0) close(errFd);
    outLines.flush();
    errLines.flush();

    // The child may outlive its pipes (rare); escalate after a grace period.
    double waitStart = now_seconds();
    while (!reaped) {
        pid_t w = waitpid(pid, &status, WNOHANG);
        if (w == pid) break;
        if (w < 0 && errno != EINTR) break;
        double t = now_seconds();
        if (is_cancelled(opt.cancel) && !terminated) { res.cancelled = true; terminate(); }
        if (terminated && killAt > 0 && t > killAt) { kill(-pid, SIGKILL); kill(pid, SIGKILL); killAt = -1; }
        if (t - waitStart > 5 && !terminated) terminate();
        usleep(10000);
    }
    if (WIFEXITED(status)) res.exitCode = WEXITSTATUS(status);
    else res.exitCode = -1;
    return res;
}

}  // namespace fa

#endif  // FA_PROCESS_UNAVAILABLE
