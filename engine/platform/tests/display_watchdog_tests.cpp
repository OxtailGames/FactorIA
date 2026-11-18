// The test watchdog of the macOS app loop (src/display_watchdog.h): the decision, the environment and the thread, with
// the display query injected so it runs on every host.
#include <doctest.h>

#include <atomic>
#include <chrono>
#include <map>
#include <string>
#include <thread>

#if defined(__APPLE__)
#include <signal.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;
#endif

#include "../src/display_watchdog.h"

using namespace fa::display_watchdog;

namespace {
EnvLookup env_of(std::map<std::string, std::string> vars) {
    return [vars](const char* name) -> const char* {
        auto it = vars.find(name);
        return it == vars.end() ? nullptr : it->second.c_str();
    };
}

bool wait_for(const std::atomic<int>& counter, int want, double seconds) {
    const auto end = std::chrono::steady_clock::now() + std::chrono::duration<double>(seconds);
    while (counter.load() < want && std::chrono::steady_clock::now() < end)
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    return counter.load() >= want;
}
}  // namespace

TEST_CASE("display watchdog: the decision") {
    // No frame for the limit and every display asleep: skip.
    CHECK(should_skip(10.0, 10.0, DisplayState::AllAsleep, false));
    CHECK(should_skip(60.0, 10.0, DisplayState::AllAsleep, false));
    // Frames came recently: never.
    CHECK_FALSE(should_skip(3.0, 10.0, DisplayState::AllAsleep, false));
    // Displays awake (a slow frame on a loaded machine) or none listed: never.
    CHECK_FALSE(should_skip(600.0, 10.0, DisplayState::Awake, false));
    CHECK_FALSE(should_skip(600.0, 10.0, DisplayState::None, false));
    // FA_TEST_IGNORE_DISPLAY_SLEEP: run whatever the display says.
    CHECK_FALSE(should_skip(600.0, 10.0, DisplayState::AllAsleep, true));
}

TEST_CASE("display watchdog: the environment") {
    CHECK_FALSE(wanted(env_of({})));
    CHECK(wanted(env_of({{"FA_EDITOR_AUTOTEST", "1"}})));
    CHECK(wanted(env_of({{"FA_EDITOR_AUTOTEST", "welcome"}})));
    CHECK(wanted(env_of({{"FA_TEST_DISPLAY_WATCHDOG", "1"}})));
    CHECK_FALSE(wanted(env_of({{"FA_TEST_DISPLAY_WATCHDOG", "0"}})));
    CHECK_FALSE(wanted(env_of({{"FA_TEST_DISPLAY_WATCHDOG", ""}})));
    CHECK_FALSE(ignore_sleep(env_of({})));
    CHECK(ignore_sleep(env_of({{"FA_TEST_IGNORE_DISPLAY_SLEEP", "1"}})));
    CHECK_FALSE(ignore_sleep(env_of({{"FA_TEST_IGNORE_DISPLAY_SLEEP", "0"}})));
    CHECK_FALSE(fake_asleep(env_of({})));
    CHECK(fake_asleep(env_of({{"FA_TEST_FAKE_DISPLAYS_ASLEEP", "1"}})));
}

TEST_CASE("display watchdog: the thread skips once when no frame comes and every display sleeps") {
    std::atomic<int> skips{0};
    std::string said;
    Options o;
    o.idleSeconds = 0.1;
    o.pollSeconds = 0.01;
    o.query = [] { return DisplayState::AllAsleep; };
    o.onSkip = [&](const std::string& line) {
        said = line;
        ++skips;
    };
    {
        Watchdog w(o);
        REQUIRE(wait_for(skips, 1, 10.0));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        CHECK(skips.load() == 1);  // once
    }
    CHECK(said.find("every display of this Mac is asleep") != std::string::npos);
    CHECK(said.find("skipped") == 0);
}

TEST_CASE("display watchdog: the thread does nothing with awake displays, with frames, or told to ignore") {
    std::atomic<int> skips{0};
    std::atomic<int> queries{0};
    Options o;
    o.idleSeconds = 0.05;
    o.pollSeconds = 0.01;
    o.onSkip = [&](const std::string&) { ++skips; };

    SUBCASE("awake displays: a slow frame is not a skip") {
        o.query = [&] {
            ++queries;
            return DisplayState::Awake;
        };
        Watchdog w(o);
        CHECK(wait_for(queries, 3, 10.0));  // it looked, more than once
        CHECK(skips.load() == 0);
    }
    SUBCASE("ignore: the sleep is not looked at") {
        o.ignoreSleep = true;
        o.query = [&] {
            ++queries;
            return DisplayState::AllAsleep;
        };
        Watchdog w(o);
        CHECK(wait_for(queries, 3, 10.0));
        CHECK(skips.load() == 0);
    }
    SUBCASE("frames keep coming: the displays are not even asked") {
        o.idleSeconds = 30.0;
        o.query = [&] {
            ++queries;
            return DisplayState::AllAsleep;
        };
        Watchdog w(o);
        for (int i = 0; i < 20; ++i) {
            w.frame();
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
        CHECK(queries.load() == 0);
        CHECK(skips.load() == 0);
    }
}

TEST_CASE("display watchdog: the fake holds back the frames too, so a window that draws still skips") {
    std::atomic<int> skips{0};
    Options o;
    o.idleSeconds = 0.1;
    o.pollSeconds = 0.01;
    o.fakeNoFrames = true;
    o.query = [] { return DisplayState::AllAsleep; };
    o.onSkip = [&](const std::string&) { ++skips; };
    Watchdog w(o);
    for (int i = 0; i < 100 && skips.load() == 0; ++i) {
        w.frame();  // frames keep coming, as on an awake display
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    CHECK(wait_for(skips, 1, 10.0));
}

TEST_CASE("display watchdog: the system query answers without a display session") {
    // Whatever the host says, it is one of the three answers and the call returns.
    const DisplayState s = query_system_displays();
    CHECK((s == DisplayState::None || s == DisplayState::Awake || s == DisplayState::AllAsleep));
}

#if defined(__APPLE__)
TEST_CASE("display watchdog: end_child_processes kills a child and the child's own child") {
    // sh starts a sleeping grandchild and then sleeps itself: both must be gone, so neither can hold a pipe of ctest.
    char sh[] = "/bin/sh";
    char dashC[] = "-c";
    char script[] = "sleep 60 & sleep 60";
    char* argv[] = {sh, dashC, script, nullptr};
    pid_t child = 0;
    REQUIRE(posix_spawn(&child, "/bin/sh", nullptr, nullptr, argv, environ) == 0);
    // Give sh a moment to start its own child (the search follows the chain of parents).
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    end_child_processes();
    int status = 0;
    REQUIRE(waitpid(child, &status, 0) == child);
    CHECK(WIFSIGNALED(status));
    CHECK(WTERMSIG(status) == SIGKILL);
}
#endif
