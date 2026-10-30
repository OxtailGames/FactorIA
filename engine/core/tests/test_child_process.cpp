#include <doctest.h>

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <string>
#include <thread>

#include "fa/core/child_process.h"
#include "fa/core/fs.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// The program tests/programs/echo_child.cpp (ctest sets FA_ECHO_CHILD; run by hand without it, these cases do nothing).
std::string echo_child() {
    const char* p = std::getenv("FA_ECHO_CHILD");
    return p ? p : "";
}

}  // namespace

TEST_CASE("child_process: lines go in and come back") {
    const std::string exe = echo_child();
    if (exe.empty()) return;
    auto child = ChildProcess::start(ChildOptions{{exe}, "", {}, {}});
    REQUIRE_MESSAGE(child.ok(), child.error().message);
    std::string line;
    REQUIRE((*child)->write("hello\n"));
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    CHECK(line == "echo: hello");
    REQUIRE((*child)->write("twice\n"));
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    CHECK(line == "one");
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    CHECK(line == "two");
    CHECK((*child)->running());
}

TEST_CASE("child_process: a read times out, then gets the answer that comes later") {
    const std::string exe = echo_child();
    if (exe.empty()) return;
    auto child = ChildProcess::start(ChildOptions{{exe}, "", {}, {}});
    REQUIRE(child.ok());
    std::string line;
    const auto t0 = std::chrono::steady_clock::now();
    CHECK((*child)->read_line(line, 0.2) == ChildProcess::Read::Timeout);
    CHECK(std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 5.0);
    REQUIRE((*child)->write("late\n"));
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    CHECK(line == "echo: late");
}

TEST_CASE("child_process: the environment is the inherited one plus the overrides") {
    const std::string exe = echo_child();
    if (exe.empty()) return;
    ChildOptions options{{exe}, "", {{"FA_CHILD_TEST_VAR", "from the options"}}, {}};
    auto child = ChildProcess::start(options);
    REQUIRE(child.ok());
    std::string line;
    REQUIRE((*child)->write("env FA_CHILD_TEST_VAR\n"));
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    CHECK(line == "from the options");
    REQUIRE((*child)->write("env FA_ECHO_CHILD\n"));
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    CHECK(line == exe);  // inherited
}

TEST_CASE("child_process: the working directory and the standard error") {
    const std::string exe = echo_child();
    if (exe.empty()) return;
    const stdfs::path dir = fs::make_temp_dir("childproc");
    ChildOptions options{{exe}, dir.string(), {}, {}};
    auto child = ChildProcess::start(options);
    REQUIRE(child.ok());
    std::string line;
    REQUIRE((*child)->write("cwd\n"));
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    std::error_code ec;
    CHECK(stdfs::equivalent(stdfs::path(line), dir, ec));
    REQUIRE((*child)->write("err something went wrong\n"));
    REQUIRE((*child)->write("after\n"));
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Line);
    CHECK(line == "echo: after");  // the standard error is never mixed into the lines
    CHECK((*child)->stderr_tail().find("something went wrong") != std::string::npos);
    child->reset();
    stdfs::remove_all(dir, ec);
}

TEST_CASE("child_process: exit is reported as Closed, and a missing program as an error with a hint") {
    const std::string exe = echo_child();
    if (exe.empty()) return;
    auto child = ChildProcess::start(ChildOptions{{exe}, "", {}, {}});
    REQUIRE(child.ok());
    REQUIRE((*child)->write("quit\n"));
    std::string line;
    CHECK((*child)->read_line(line, 10) == ChildProcess::Read::Closed);
    CHECK_FALSE((*child)->running());
    CHECK_FALSE((*child)->write("more\n"));

    auto missing = ChildProcess::start(ChildOptions{{"fa-no-such-program-for-the-test"}, "", {}, {}});
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("fa-no-such-program-for-the-test") != std::string::npos);
    CHECK_FALSE(missing.error().hint.empty());
    auto empty = ChildProcess::start(ChildOptions{});
    CHECK_FALSE(empty.ok());
}

TEST_CASE("child_process: cancel stops a read, terminate kills the program") {
    const std::string exe = echo_child();
    if (exe.empty()) return;
    auto child = ChildProcess::start(ChildOptions{{exe}, "", {}, {}});
    REQUIRE(child.ok());
    CancelFlag cancel{false};
    std::thread setter([&cancel] {
        std::this_thread::sleep_for(std::chrono::milliseconds(150));
        cancel = true;
    });
    std::string line;
    const auto t0 = std::chrono::steady_clock::now();
    CHECK((*child)->read_line(line, 30, &cancel) == ChildProcess::Read::Cancelled);
    setter.join();
    CHECK(std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 10.0);
    (*child)->terminate();
    CHECK_FALSE((*child)->running());
    (*child)->terminate();  // idempotent
}
