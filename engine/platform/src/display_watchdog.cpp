#include "display_watchdog.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <utility>

namespace fa::display_watchdog {

bool should_skip(double idleSeconds, double limitSeconds, DisplayState displays, bool ignoreSleep) {
    if (ignoreSleep) return false;
    return idleSeconds >= limitSeconds && displays == DisplayState::AllAsleep;
}

namespace {
bool flag_set(const EnvLookup& lookup, const char* name) {
    const char* v = lookup ? lookup(name) : nullptr;
    return v != nullptr && v[0] != '\0' && std::strcmp(v, "0") != 0;
}

void skip_and_exit(const std::string& line) {
    std::fprintf(stderr, "%s\n", line.c_str());
    std::fflush(stderr);
    std::fflush(stdout);
    std::_Exit(kSkipExitCode);  // from the watchdog's thread: no destructors, nothing else may run
}
}  // namespace

bool wanted(const EnvLookup& lookup) {
    return flag_set(lookup, "FA_EDITOR_AUTOTEST") || flag_set(lookup, "FA_TEST_DISPLAY_WATCHDOG");
}
bool ignore_sleep(const EnvLookup& lookup) { return flag_set(lookup, "FA_TEST_IGNORE_DISPLAY_SLEEP"); }
bool fake_asleep(const EnvLookup& lookup) { return flag_set(lookup, "FA_TEST_FAKE_DISPLAYS_ASLEEP"); }

int64_t Watchdog::now_ns() {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now().time_since_epoch())
        .count();
}

Watchdog::Watchdog(Options options) : options_(std::move(options)), lastFrameNs_(now_ns()) {
    if (!options_.query) options_.query = query_system_displays;
    if (!options_.onSkip) options_.onSkip = skip_and_exit;
    thread_ = std::thread([this] { run(); });
}

Watchdog::~Watchdog() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        stop_ = true;
    }
    wake_.notify_all();
    if (thread_.joinable()) thread_.join();
}

void Watchdog::frame() {
    if (options_.fakeNoFrames) return;
    lastFrameNs_.store(now_ns(), std::memory_order_relaxed);
}

void Watchdog::run() {
    const auto poll = std::chrono::duration<double>(options_.pollSeconds);
    std::unique_lock<std::mutex> lock(mutex_);
    while (!stop_) {
        wake_.wait_for(lock, poll, [this] { return stop_; });
        if (stop_) return;
        const double idle = double(now_ns() - lastFrameNs_.load(std::memory_order_relaxed)) / 1e9;
        if (idle < options_.idleSeconds) continue;
        const DisplayState state = options_.query();  // only when frames are late: a system call
        if (should_skip(idle, options_.idleSeconds, state, options_.ignoreSleep)) {
            options_.onSkip("skipped: every display of this Mac is asleep, no window gets a frame; wake the display or "
                            "leave it to CI");
            return;
        }
    }
}

#if !defined(__APPLE__)
// No system query here: Linux runs under Xvfb, Windows has its desktop session (display_watchdog_apple.mm is macOS's).
DisplayState query_system_displays() { return DisplayState::None; }
#endif

}  // namespace fa::display_watchdog
