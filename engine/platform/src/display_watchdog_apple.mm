// The displays of this Mac, for the test watchdog (display_watchdog.h).
#include <TargetConditionals.h>

#include <cstdlib>
#include <vector>

#include "display_watchdog.h"

#if !TARGET_OS_IPHONE
#include <CoreGraphics/CoreGraphics.h>
#include <libproc.h>  // only in the macOS SDK
#include <signal.h>
#include <unistd.h>
#endif

namespace fa::display_watchdog {

DisplayState query_system_displays() {
    if (fake_asleep([](const char* name) { return std::getenv(name); })) return DisplayState::AllAsleep;
#if TARGET_OS_IPHONE
    return DisplayState::None;
#else
    // The online list keeps a display that sleeps (the active list drops it), so "asleep" is told by CGDisplayIsAsleep.
    CGDirectDisplayID ids[32];
    uint32_t count = 0;
    if (CGGetOnlineDisplayList(32, ids, &count) != kCGErrorSuccess || count == 0) return DisplayState::None;
    for (uint32_t i = 0; i < count && i < 32; ++i) {
        if (!CGDisplayIsAsleep(ids[i])) return DisplayState::Awake;
    }
    return DisplayState::AllAsleep;
#endif
}

#if !TARGET_OS_IPHONE
namespace {
// The pids of the direct children of `pid` (libproc; an empty list on any error).
std::vector<pid_t> children_of(pid_t pid) {
    std::vector<pid_t> out(64);
    for (int attempt = 0; attempt < 4; ++attempt) {
        // The answer is the NUMBER of pids written (measured on macOS: one child gives 1, not 4), whatever the
        // header's "buffersize" suggests.
        const int written = proc_listchildpids(pid, out.data(), int(out.size() * sizeof(pid_t)));
        if (written <= 0) return {};
        const size_t count = size_t(written);
        if (count < out.size()) {
            out.resize(count);
            return out;
        }
        out.resize(out.size() * 4);  // the list may have been cut: ask again with more room
    }
    return out;
}
}  // namespace

void end_child_processes() {
    // Two accepted limits. PID reuse: a pid listed here could exit and be reused by an unrelated process before the
    // kill; the window is the few microseconds between the listing and the signal (and the SIGSTOP below holds the
    // listed ones in place), on a process that is about to _Exit anyway. A grandchild whose parent died before the
    // listing was reparented to launchd (pid 1), so no walk from getpid() finds it: it can outlive the skip.
    // Breadth first, children of children too; a bound keeps a fork bomb from keeping the thread here.
    std::vector<pid_t> queue = children_of(getpid());
    for (size_t i = 0; i < queue.size() && i < 4096; ++i) {
        const pid_t pid = queue[i];
        if (pid <= 1) continue;
        kill(pid, SIGSTOP);  // stopped first so that it cannot fork again while its children are being listed
        for (pid_t child : children_of(pid)) queue.push_back(child);
    }
    for (size_t i = 0; i < queue.size() && i < 4096; ++i) {
        if (queue[i] > 1) kill(queue[i], SIGKILL);
    }
}
#else
void end_child_processes() {}  // iOS: no libproc, and a phone app has no children
#endif

}  // namespace fa::display_watchdog
