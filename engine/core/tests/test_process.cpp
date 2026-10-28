#include <doctest.h>

#include <chrono>
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

#endif  // !_WIN32

#ifndef _WIN32

TEST_CASE("process: onStart gives the pid, process_tree sees the program and what it started, and sees it end") {
    ProcessOptions po;
    po.argv = {"/bin/sh", "-c", "sleep 3 & wait"};
    long long pid = 0;
    std::vector<ProcessEntry> during;
    po.onStart = [&](long long p) { pid = p; };
    po.onStdoutLine = [](std::string_view) {};
    CancelFlag cancel{false};
    po.cancel = &cancel;
    std::thread watcher([&] {
        for (int i = 0; i < 100 && during.size() < 2; ++i) {
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

#endif  // !_WIN32

#ifdef _WIN32

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
