// play.auto in a child process (fa/tooling/play_auto.h, play_auto_in_child): what the editor's AI agent threads call. A stand-in `factoria`
// (a shell script, or a .cmd file on Windows) plays the child, named by FA_FACTORIA_EXE.
#include <doctest.h>

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <thread>

#include "fa/core/fs.h"
#include "fa/tooling/play_auto.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

void set_env(const char* name, const char* value) {
#if defined(_WIN32)
    _putenv_s(name, value ? value : "");
#else
    if (value) setenv(name, value, 1);
    else unsetenv(name);
#endif
}

// A stand-in `factoria`. `windows` uses only what a .cmd argument line may hold.
std::string stand_in(const stdfs::path& dir, const std::string& posix, const std::string& windows) {
#if defined(_WIN32)
    const stdfs::path file = dir / "factoria.cmd";
    {
        std::ofstream f(file, std::ios::binary);
        f << "@echo off\r\n" << windows << "\r\n";
    }
    (void)posix;
#else
    const stdfs::path file = dir / "factoria";
    {
        std::ofstream f(file, std::ios::binary);
        f << "#!/bin/sh\n" << posix << "\n";
    }
    stdfs::permissions(file, stdfs::perms::owner_all, stdfs::perm_options::add);
    (void)windows;
#endif
    return fs::path_to_utf8(file);
}

struct ScopedExe {
    explicit ScopedExe(const std::string& path) { set_env("FA_FACTORIA_EXE", path.c_str()); }
    ~ScopedExe() { set_env("FA_FACTORIA_EXE", nullptr); }
};

}  // namespace

TEST_CASE("factoria_executable: FA_FACTORIA_EXE names a file, and a wrong one is not replaced") {
    testing::TempDir tmp;
    {
        ScopedExe exe(stand_in(tmp.path, "exit 0", "@exit /b 0"));
        CHECK_FALSE(factoria_executable().empty());
    }
    {
        ScopedExe exe(fs::path_to_utf8(tmp.path / "missing"));
        CHECK(factoria_executable().empty());
    }
}

TEST_CASE("play_auto_in_child: the child's answer comes back, and its error keeps its message and hint") {
    testing::TempDir tmp;
    const stdfs::path project = tmp.path / stdfs::path(u8"juego-José");  // an accent: the child must start in this folder
    std::error_code ec;
    stdfs::create_directories(project, ec);
    {
        ScopedExe exe(stand_in(tmp.path, "echo here > here.txt\necho '{\"session\":\"20260101-000000-auto\",\"ended\":\"won\"}'",
                               "@echo here > here.txt\r\n@echo {\"session\":\"20260101-000000-auto\",\"ended\":\"won\"}"));
        const Json r = play_auto_in_child(project.string(), Json::object({{"seconds", 5}}), nullptr);
        CHECK(r.value("ended", std::string()) == "won");
        CHECK(stdfs::exists(project / "here.txt"));  // its working directory is the project, UTF-8 all the way
    }
    {
        ScopedExe exe(stand_in(tmp.path, "echo '{\"ok\":false,\"error\":{\"code\":\"invalid_argument\",\"message\":\"/seconds: bad\",\"hint\":\"Use 60.\"}}'\nexit 1",
                               "@echo {\"ok\":false,\"error\":{\"code\":\"invalid_argument\",\"message\":\"/seconds: bad\",\"hint\":\"Use 60.\"}}\r\n@exit /b 1"));
        try {
            play_auto_in_child(project.string(), Json::object(), nullptr);
            FAIL("the child's error should be thrown");
        } catch (const CommandError& e) {
            CHECK(e.code == "invalid_argument");
            CHECK(std::string(e.what()).find("/seconds: bad") != std::string::npos);
            CHECK(e.hint == "Use 60.");
        }
    }
}

TEST_CASE("play_auto_in_child: cancel kills a long child promptly and the command fails as cancelled") {
    testing::TempDir tmp;
    ScopedExe exe(stand_in(tmp.path, "sleep 120", "ping -n 120 127.0.0.1 >nul"));
    CancelFlag cancel{false};
    std::thread stopper([&cancel] {
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        cancel = true;
    });
    const auto start = std::chrono::steady_clock::now();
    std::string code;
    try {
        play_auto_in_child(tmp.str(), Json::object(), &cancel);
    } catch (const CommandError& e) {
        code = e.code;
    }
    stopper.join();
    const double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
    CHECK(code == "cancelled");
    CHECK(seconds < 60);  // far from the 120 s the child would have slept, and from the 900 s timeout
}
