// The numbers each platform's rumble API wants (see fa/platform/gamepad_rumble_map.h).
#include "fa/platform/gamepad_rumble_map.h"

#include <algorithm>
#include <cmath>

namespace fa {
namespace {

float unit(float v) { return v > 0.0f ? std::min(v, 1.0f) : 0.0f; }  // NaN and negatives give 0

// Rounded up to whole milliseconds, ignoring float noise (0.3f is 0.30000001: 300 ms, not 301).
long long whole_ms(float seconds) {
    if (!(seconds > 0.0f)) return 1;
    return std::max<long long>(1, (long long)std::ceil(double(seconds) * 1000.0 - 0.01));
}

}  // namespace

EvdevRumble evdev_rumble(float low, float high, float seconds) {
    EvdevRumble r;
    r.strong = std::uint16_t(std::lround(unit(low) * 65535.0f));
    r.weak = std::uint16_t(std::lround(unit(high) * 65535.0f));
    const long long ms = whole_ms(seconds);
    r.clamped = ms > 0xFFFF;
    r.lengthMs = std::uint16_t(std::min<long long>(ms, 0xFFFF));
    return r;
}

AndroidRumble android_rumble(float low, float high, float seconds, int vibrators) {
    auto amplitude = [](float v) { return v > 0.0f ? std::clamp(int(std::lround(unit(v) * 255.0f)), 1, 255) : 0; };
    AndroidRumble r;
    r.millis = std::min(whole_ms(seconds), kAndroidRumbleMaxMillis);
    if (vibrators <= 1) {
        r.amplitude[0] = amplitude(std::max(unit(low), unit(high)));
    } else {
        r.amplitude[0] = amplitude(low);
        r.amplitude[1] = amplitude(high);
    }
    return r;
}

AppleRumble apple_rumble(float low, float high, float seconds, bool haveLeft, bool haveRight) {
    AppleRumble r;
    r.split = haveLeft && haveRight;
    if (r.split) {
        r.left = unit(low);
        r.right = unit(high);
    } else {
        r.left = std::max(unit(low), unit(high));
    }
    r.seconds = seconds > 0.0f ? std::clamp(seconds, 0.01f, kAppleHapticMaxSeconds) : 0.01f;
    return r;
}

}  // namespace fa
