// The displays of this Mac, for the test watchdog (display_watchdog.h).
#include <TargetConditionals.h>

#include <cstdlib>

#include "display_watchdog.h"

#if !TARGET_OS_IPHONE
#include <CoreGraphics/CoreGraphics.h>
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

}  // namespace fa::display_watchdog
