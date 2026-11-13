#include <doctest.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/process.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// Unique empty temp directory, removed on destruction.
struct TempDir {
    stdfs::path path;
    TempDir() {
        path = stdfs::temp_directory_path() /
               ("fa_test_process_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        stdfs::remove_all(path);
        stdfs::create_directories(path);
    }
    ~TempDir() {
        std::error_code ec;
        stdfs::remove_all(path, ec);
    }
    std::string str() const { return path.string(); }
};

}  // namespace

TEST_CASE("process: CancelFlag and is_cancelled") {
    CancelFlag flag{false};
    CHECK_FALSE(is_cancelled(nullptr));
    CHECK_FALSE(is_cancelled(&flag));
    flag = true;
    CHECK(is_cancelled(&flag));
}

TEST_CASE("process: an empty argv is an error that says what to pass") {
    auto r = run_process(ProcessOptions{});
    REQUIRE_FALSE(r.ok());
    CHECK_FALSE(r.error().message.empty());
    CHECK_FALSE(r.error().hint.empty());
}

#ifndef _WIN32

TEST_CASE("process runner: lines, stderr, exit code, env, cwd") {
    TempDir dir;
    ProcessOptions po;
    po.argv = {"sh", "-c", "echo one; echo two >&2; echo \"$FA_TEST_VAR\"; pwd; printf partial; exit 3"};
    po.env["FA_TEST_VAR"] = "hello";
    po.workingDir = dir.str();
    std::vector<std::string> lines, errs;
    po.onStdoutLine = [&](std::string_view l) { lines.emplace_back(l); };
    po.onStderrLine = [&](std::string_view l) { errs.emplace_back(l); };
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->exitCode == 3);
    REQUIRE(lines.size() == 4);
    CHECK(lines[0] == "one");
    CHECK(lines[1] == "hello");
    CHECK(stdfs::equivalent(lines[2], dir.path));
    CHECK(lines[3] == "partial");  // trailing line without newline is flushed
    REQUIRE(errs.size() == 1);
    CHECK(errs[0] == "two");
    CHECK(r->stderrText == "two\n");
}

TEST_CASE("process runner: unset env, missing executable, which") {
    ProcessOptions po;
    po.argv = {"sh", "-c", "echo \"[${HOME-unset}]\""};
    po.unsetEnv = {"HOME"};
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->stdoutText == "[unset]\n");

    ProcessOptions bad;
    bad.argv = {"definitely-not-a-real-program-xyz"};
    auto b = run_process(bad);
    REQUIRE_FALSE(b.ok());
    CHECK(b.error().message.find("definitely-not-a-real-program-xyz") != std::string::npos);
    CHECK_FALSE(b.error().hint.empty());

    CHECK_FALSE(which("sh").empty());
    CHECK(which("definitely-not-a-real-program-xyz").empty());
    CHECK(which("/bin/sh") == "/bin/sh");
}

TEST_CASE("process runner: lines arrive incrementally and cancel kills the process tree") {
    CancelFlag cancel{false};
    ProcessOptions po;
    po.argv = {"sh", "-c", "echo first; sleep 30; echo never"};
    po.cancel = &cancel;
    std::vector<std::string> lines;
    po.onStdoutLine = [&](std::string_view l) {
        lines.emplace_back(l);
        cancel = true;  // cancel as soon as the first line is seen
    };
    auto t0 = std::chrono::steady_clock::now();
    auto r = run_process(po);
    auto secs = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    REQUIRE(r);
    CHECK(r->cancelled);
    CHECK(lines == std::vector<std::string>{"first"});
    CHECK(secs < 10);
}

TEST_CASE("process runner: stdin text") {
    ProcessOptions po;
    po.argv = {"sh", "-c", "cat"};
    po.stdinText = "line one\nline two & \"quoted\" $HOME\n";
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->stdoutText == po.stdinText);
}

TEST_CASE("process runner: timeout") {
    ProcessOptions po;
    po.argv = {"sh", "-c", "sleep 30"};
    po.timeoutSeconds = 0.3;
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->timedOut);
}

TEST_CASE("process runner: a program still open for writing (ETXTBSY) starts once the writer closes it") {
    // Linux refuses to exec a file that is open for writing ("Text file busy"); macOS does not, and the test passes there too.
    // The launcher tries three times, 10 ms apart, in the child: the writer closes the file after 5 ms.
    TempDir dir;
    const std::string script = (dir.path / "fresh.sh").string();
    int fd = ::open(script.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0755);
    REQUIRE(fd >= 0);
    const char text[] = "#!/bin/sh\necho fresh\n";
    REQUIRE(::write(fd, text, sizeof text - 1) == ssize_t(sizeof text - 1));
    REQUIRE(::fchmod(fd, 0755) == 0);
    std::thread closer([fd] {
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
        ::close(fd);
    });
    ProcessOptions po;
    po.argv = {script};
    auto r = run_process(po);
    closer.join();
    REQUIRE_MESSAGE(bool(r), (r ? std::string() : r.error().message));
    CHECK(r->exitCode == 0);
    CHECK(r->stdoutText == "fresh\n");
}

#endif  // !_WIN32

#ifndef _WIN32

TEST_CASE("process: onStart gives the pid, process_tree sees the program and what it started, and sees it end") {
    ProcessOptions po;
    po.argv = {"/bin/sh", "-c", "sleep 3 & wait"};
    std::atomic<long long> pid{0};  // written by run_process on this thread, read by the watcher thread
    std::vector<ProcessEntry> during;
    po.onStart = [&](long long p) { pid = p; };
    po.onStdoutLine = [](std::string_view) {};
    CancelFlag cancel{false};
    po.cancel = &cancel;
    // Wait for the child to be "sleep", not only to exist: between fork and exec it is still a copy named "sh", which a
    // slow or emulated machine shows for longer.
    auto sees_sleep = [&] { return during.size() >= 2 && during[1].name == "sleep"; };
    std::thread watcher([&] {
        for (int i = 0; i < 100 && !sees_sleep(); ++i) {
            std::this_thread::sleep_for(std::chrono::milliseconds(30));
            if (pid) during = process_tree(pid);
        }
        cancel = true;
    });
    auto r = run_process(po);
    watcher.join();
    REQUIRE(r);
    REQUIRE(pid > 0);
    REQUIRE(during.size() >= 2);  // the shell and its sleep
    CHECK(during[0].pid == pid);
    CHECK(during[0].name.find("sh") != std::string::npos);
    CHECK(during[1].parentPid == pid);
    CHECK(during[1].name == "sleep");
    CHECK(during[1].cpuSeconds >= 0);
    CHECK(process_tree(pid).empty());  // gone
    CHECK(process_tree(0).empty());
}

TEST_CASE("process: endWithChild returns when the program exits although a descendant holds its pipes") {
    ProcessOptions po;
    po.argv = {"/bin/sh", "-c", "sleep 30 & echo started"};  // the background sleep inherits stdout
    std::vector<std::string> lines;
    po.onStdoutLine = [&](std::string_view l) { lines.emplace_back(l); };
    po.endWithChild = true;
    const auto t0 = std::chrono::steady_clock::now();
    auto r = run_process(po);
    const double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    REQUIRE(r);
    CHECK(r->exitCode == 0);
    CHECK(lines == std::vector<std::string>{"started"});
    CHECK(seconds < 10);  // without the flag this would take the 30 s of the sleep
}

// Regression: on macOS proc_listallpids returns a count, which was read as bytes, so the list kept only the newest ~50
// pids and an older process (the editor's agent) looked gone as soon as many processes had started after it.
TEST_CASE(
    "process: process_tree finds this process and its parent among many newer processes, process_alive asks the OS") {
    std::vector<pid_t> kids;
    for (int i = 0; i < 80; ++i) {
        const pid_t k = fork();
        REQUIRE(k >= 0);
        if (k == 0) {
            pause();
            _exit(0);
        }
        kids.push_back(k);
    }
    const long long self = getpid(), parent = getppid();
    const std::vector<ProcessEntry> mine = process_tree(self);
    REQUIRE_FALSE(mine.empty());
    CHECK(mine[0].pid == self);
    std::size_t found = 0;
    for (const ProcessEntry& p : mine)
        if (p.parentPid == self) ++found;
    CHECK(found == kids.size());  // every child, the newest ones included
    CHECK_FALSE(process_tree(parent).empty());
    CHECK(process_alive(self));
    CHECK(process_alive(parent));
    CHECK(process_alive(kids.front()));
    CHECK_FALSE(process_alive(0));
    CHECK_FALSE(process_alive(-5));

    for (pid_t k : kids) kill(k, SIGKILL);
    for (pid_t k : kids) waitpid(k, nullptr, 0);
    CHECK_FALSE(process_alive(kids.front()));  // reaped
    CHECK(process_tree(kids.front()).empty());
    CHECK(process_alive(self));
}

TEST_CASE("process: process_alive is false for a zombie (exited, not yet waited for)") {
    const pid_t k = fork();
    REQUIRE(k >= 0);
    if (k == 0) _exit(0);
    bool dead = false;
    for (int i = 0; i < 200 && !dead; ++i) {
        dead = !process_alive(k);
        if (!dead) std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    CHECK(dead);
    waitpid(k, nullptr, 0);
    CHECK_FALSE(process_alive(k));
}

// ---- ProcessOptions::newSession --------------------------------------------------------------------------------------

TEST_CASE("process: newSession gives the program a session of its own (no controlling terminal), default keeps ours") {
    for (bool newSession : {false, true}) {
        INFO("newSession " << newSession);
        ProcessOptions po;
        po.argv = {"sh", "-c", "sleep 0.5"};
        po.newSession = newSession;
        pid_t childPid = 0, childSid = -1, childGroup = -1;
        po.onStart = [&](long long pid) {
            childPid = static_cast<pid_t>(pid);
            childSid = getsid(childPid);
            childGroup = getpgid(childPid);
        };
        auto r = run_process(po);
        REQUIRE(r);
        CHECK(r->exitCode == 0);
        REQUIRE(childPid > 0);
        CHECK(childGroup == childPid);  // its own group either way: a cancel signals the whole tree
        if (newSession)
            CHECK(childSid == childPid);  // a session leader
        else
            CHECK(childSid == getsid(0));
    }
}

// (Without a terminal at all, e.g. on CI, /dev/tty cannot be opened with or without newSession: the session check is what proves it.)
TEST_CASE(
    "process: newSession program reads the stdin text, leads a session that is not ours, and cannot open /dev/tty") {
    ProcessOptions po;
    po.argv = {"sh", "-c", "read pw; echo \"got:$pw\"; (: < /dev/tty) 2>/dev/null && echo tty || echo notty; exit 3"};
    po.stdinText = "secret\n";
    po.newSession = true;
    po.timeoutSeconds = 30;
    pid_t childPid = 0, childSid = -1;
    po.onStart = [&](long long pid) {
        childPid = static_cast<pid_t>(pid);
        childSid = getsid(childPid);
    };
    auto r = run_process(po);
    REQUIRE(r);
    REQUIRE(childPid > 0);
    CHECK(childSid == childPid);
    CHECK(childSid != getsid(0));
    CHECK(r->exitCode == 3);
    CHECK(r->stdoutText == "got:secret\nnotty\n");
}

namespace {

// Starts `script` (a shell program that prints the pid of a grandchild on its first line), cancels as soon as that line is seen and
// returns the result; `grandchild` is that pid. Waits (up to 10 s) for the OS to say the grandchild is gone.
struct GrandchildRun {
    ProcessResult result;
    long long grandchild = 0;
    bool gone = false;
    double seconds = 0;
};

GrandchildRun run_and_cancel(const char* script, bool newSession) {
    GrandchildRun out;
    CancelFlag cancel{false};
    ProcessOptions po;
    po.argv = {"sh", "-c", script};
    po.newSession = newSession;
    po.cancel = &cancel;
    po.onStdoutLine = [&](std::string_view l) {
        if (out.grandchild == 0) out.grandchild = std::atoll(std::string(l).c_str());
        cancel = true;
    };
    const auto t0 = std::chrono::steady_clock::now();
    auto r = run_process(po);
    out.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    REQUIRE(r);
    out.result = *r;
    for (int i = 0; i < 1000 && !out.gone; ++i) {
        out.gone = !process_alive(out.grandchild);
        if (!out.gone) std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    return out;
}

}  // namespace

TEST_CASE("process: a cancel reaches a grandchild, with and without newSession") {
    for (bool newSession : {false, true}) {
        INFO("newSession " << newSession);
        auto run = run_and_cancel("sleep 30 & echo $!; wait", newSession);
        CHECK(run.result.cancelled);
        REQUIRE(run.grandchild > 1);
        CHECK(run.gone);
        CHECK(run.seconds < 10);
    }
}

TEST_CASE(
    "process: a program that ignores SIGTERM, and its grandchild, are killed after the grace period (newSession)") {
    auto run = run_and_cancel("trap '' TERM; sleep 30 & echo $!; wait", true);
    CHECK(run.result.cancelled);
    REQUIRE(run.grandchild > 1);
    CHECK(run.gone);
    CHECK(run.seconds < 10);
}

TEST_CASE("process: a cancel sends SIGTERM first, so a program can clean up (trap) - newSession too") {
    for (bool newSession : {false, true}) {
        INFO("newSession " << newSession);
        CancelFlag cancel{false};
        ProcessOptions po;
        po.argv = {"sh", "-c", "trap 'echo termed; exit 7' TERM; echo ready; while :; do sleep 0.1; done"};
        po.newSession = newSession;
        po.cancel = &cancel;
        po.onStdoutLine = [&](std::string_view l) {
            if (l == "ready") cancel = true;
        };
        const auto t0 = std::chrono::steady_clock::now();
        auto r = run_process(po);
        const double secs = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        REQUIRE(r);
        CHECK(r->cancelled);
        CHECK(r->exitCode == 7);  // it ran its trap and exited by itself, not killed
        CHECK(r->stdoutText == "ready\ntermed\n");
        CHECK(secs < 10);
    }
}

#endif  // !_WIN32

#ifdef _WIN32

TEST_CASE("process: process_alive is true for this process, false for an invalid pid") {
    CHECK(process_alive(static_cast<long long>(GetCurrentProcessId())));
    CHECK_FALSE(process_alive(0));
}

// npm installs claude and codex as .cmd files, which run through cmd.exe.
TEST_CASE("process runner: .cmd in a path with spaces, multi-line stdin, unsafe arguments refused") {
    TempDir dir;
    stdfs::create_directories(dir.path / "npm dir");
    std::string cmd = (dir.path / "npm dir" / "fake cli.cmd").string();
    std::ofstream(cmd) << "@echo arg:%~1\r\n@findstr \"^\"\r\n";

    ProcessOptions po;
    po.argv = {cmd, "two words"};
    po.stdinText = "line one\nline two & \"quoted\" %PATH%\n";
    std::vector<std::string> lines;
    po.onStdoutLine = [&](std::string_view l) { lines.emplace_back(l); };
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->exitCode == 0);
    CHECK(lines == std::vector<std::string>{"arg:two words", "line one", "line two & \"quoted\" %PATH%"});

    for (const char* arg : {"line one\nline two", "100%", "a & calc"}) {
        ProcessOptions bad;
        bad.argv = {cmd, arg};
        auto b = run_process(bad);
        REQUIRE_FALSE(b.ok());
        CHECK(b.error().message.find(".cmd/.bat") != std::string::npos);
        CHECK(b.error().hint.find("{prompt}") != std::string::npos);
    }
}

#endif  // _WIN32
