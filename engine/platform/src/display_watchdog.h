// Test-harness watchdog for the macOS app loop: a program that runs under a test (the editor autotest, the player of a
// ctest case) waits for frames, and on a Mac whose displays are all asleep no window gets one: the wait never ends, and
// script time limits count CPU time, so it would never reach its limit either. When no frame has come for a while AND
// every display is asleep, the watchdog says so in one line and ends the process with exit code 77, which the tests'
// SKIP_RETURN_CODE turns into "skipped" for ctest. It reads the wall clock on purpose (it is not simulation). Awake
// displays: it does nothing, a slow frame on a loaded machine is not a skip.
#pragma once

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <functional>
#include <mutex>
#include <string>
#include <thread>

namespace fa::display_watchdog {

constexpr int kSkipExitCode = 77;  // the SKIP_RETURN_CODE of the tests that open a window

// What the system says about the displays.
enum class DisplayState {
    None,       // no display is listed (a Mac mini without a monitor): the check does not apply
    Awake,      // at least one display is awake
    AllAsleep,  // there are displays and every one of them is asleep
};

// The decision: skip when no frame came for idleSeconds >= limitSeconds, every display is asleep and the run is not
// told to ignore the sleep (FA_TEST_IGNORE_DISPLAY_SLEEP).
bool should_skip(double idleSeconds, double limitSeconds, DisplayState displays, bool ignoreSleep);

using EnvLookup = std::function<const char*(const char*)>;  // getenv-like: null when the variable is not set

// The watchdog runs only in a test mode: FA_EDITOR_AUTOTEST (the editor's autotest) or FA_TEST_DISPLAY_WATCHDOG (set by
// the ctest entries that run a player).
bool wanted(const EnvLookup& lookup);
// FA_TEST_IGNORE_DISPLAY_SLEEP (not empty, not "0"): run whatever the display says (FA_AGENT_WINDOW_TESTS=run).
bool ignore_sleep(const EnvLookup& lookup);
// FA_TEST_FAKE_DISPLAYS_ASLEEP: the system query answers "all asleep" (how a ctest case checks exit 77 end to end).
bool fake_asleep(const EnvLookup& lookup);

// The system's answer. macOS: CGGetOnlineDisplayList + CGDisplayIsAsleep (display_watchdog_apple.mm), or AllAsleep when
// FA_TEST_FAKE_DISPLAYS_ASLEEP is set. Elsewhere: DisplayState::None.
DisplayState query_system_displays();

struct Options {
    double idleSeconds = 10.0;                       // no frame for this long
    double pollSeconds = 1.0;                        // how often the thread looks
    bool ignoreSleep = false;                        // FA_TEST_IGNORE_DISPLAY_SLEEP
    bool fakeNoFrames = false;                       // FA_TEST_FAKE_DISPLAYS_ASLEEP: frame() is ignored, as on a sleeping Mac
    std::function<DisplayState()> query;             // null: query_system_displays
    std::function<void(const std::string&)> onSkip;  // null: print the line to stderr and end the process with 77
};

// A thread that looks every pollSeconds; frame() is called by the app on every frame. The destructor stops and joins
// it (promptly: it waits on a condition variable). onSkip is called at most once.
class Watchdog {
public:
    explicit Watchdog(Options options);
    ~Watchdog();
    Watchdog(const Watchdog&) = delete;
    Watchdog& operator=(const Watchdog&) = delete;
    void frame();  // a frame was drawn

private:
    void run();
    static int64_t now_ns();

    Options options_;
    std::atomic<int64_t> lastFrameNs_;
    std::mutex mutex_;
    std::condition_variable wake_;
    bool stop_ = false;
    std::thread thread_;
};

}  // namespace fa::display_watchdog
