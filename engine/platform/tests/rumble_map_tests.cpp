// The rumble numbers of the Linux, Android and Apple backends (pure helpers; the backends themselves need a pad).
#include <doctest.h>

#include <limits>

#include "fa/platform/gamepad_rumble_map.h"

using namespace fa;

TEST_CASE("evdev rumble: low is the strong motor, high the weak one, 0..1 scales to 16 bits") {
    const EvdevRumble r = evdev_rumble(1.0f, 0.5f, 0.25f);
    CHECK(r.strong == 65535);
    CHECK(r.weak == 32768);
    CHECK(r.lengthMs == 250);
    CHECK_FALSE(r.clamped);
    const EvdevRumble none = evdev_rumble(0.0f, 0.0f, 1.0f);
    CHECK(none.strong == 0);
    CHECK(none.weak == 0);
}

TEST_CASE("evdev rumble: strengths are clamped, the length is whole milliseconds, never 0, and cut at 16 bits") {
    const float nan = std::numeric_limits<float>::quiet_NaN();
    EvdevRumble r = evdev_rumble(2.0f, -1.0f, 0.0004f);
    CHECK(r.strong == 65535);
    CHECK(r.weak == 0);
    CHECK(r.lengthMs == 1);  // rounded up
    r = evdev_rumble(nan, nan, nan);
    CHECK(r.strong == 0);
    CHECK(r.weak == 0);
    CHECK(r.lengthMs == 1);  // 0 would mean "forever" to some drivers
    r = evdev_rumble(1.0f, 1.0f, 10.0f);
    CHECK(r.lengthMs == 10000);
    CHECK_FALSE(r.clamped);
    r = evdev_rumble(1.0f, 1.0f, 100.0f);
    CHECK(r.lengthMs == 65535);
    CHECK(r.clamped);
    const float inf = std::numeric_limits<float>::infinity();
    r = evdev_rumble(1.0f, 1.0f, inf);  // no undefined conversion of an infinite length
    CHECK(r.lengthMs == 65535);
    CHECK(r.clamped);
    CHECK(android_rumble(1.0f, 1.0f, inf, 1).millis == kAndroidRumbleMaxMillis);
    CHECK(apple_rumble(1.0f, 1.0f, inf, true, true).seconds == kAppleHapticMaxSeconds);
}

TEST_CASE("android rumble: one vibrator plays the stronger motor, two split low and high, amplitudes are 1..255") {
    AndroidRumble r = android_rumble(0.2f, 0.8f, 0.3f, 1);
    CHECK(r.amplitude[0] == 204);
    CHECK(r.amplitude[1] == 0);
    CHECK(r.millis == 300);
    r = android_rumble(0.2f, 0.8f, 0.3f, 2);
    CHECK(r.amplitude[0] == 51);
    CHECK(r.amplitude[1] == 204);
    r = android_rumble(1.0f, 0.0f, 0.3f, 2);
    CHECK(r.amplitude[0] == 255);
    CHECK(r.amplitude[1] == 0);  // that vibrator stays off
    r = android_rumble(0.0001f, 5.0f, 0.3f, 2);
    CHECK(r.amplitude[0] == 1);  // a tiny strength is still on: createOneShot rejects 0
    CHECK(r.amplitude[1] == 255);
    r = android_rumble(0.5f, 0.5f, 0.0f, 3);
    CHECK(r.millis == 1);
    r = android_rumble(0.5f, 0.5f, 1000.0f, 1);
    CHECK(r.millis == kAndroidRumbleMaxMillis);
}

TEST_CASE("apple rumble: low to the left handle and high to the right, one engine plays the maximum") {
    AppleRumble r = apple_rumble(0.3f, 0.9f, 0.5f, true, true);
    CHECK(r.split);
    CHECK(r.left == doctest::Approx(0.3f));
    CHECK(r.right == doctest::Approx(0.9f));
    CHECK(r.seconds == doctest::Approx(0.5f));
    for (const bool left : {false, true}) {
        r = apple_rumble(0.3f, 0.9f, 0.5f, left, !left);  // a pad with only one handle uses a single engine
        CHECK_FALSE(r.split);
        CHECK(r.left == doctest::Approx(0.9f));
    }
    r = apple_rumble(0.7f, 0.1f, 0.5f, false, false);  // the default locality
    CHECK_FALSE(r.split);
    CHECK(r.left == doctest::Approx(0.7f));
    r = apple_rumble(2.0f, -3.0f, 1000.0f, true, true);
    CHECK(r.left == doctest::Approx(1.0f));
    CHECK(r.right == doctest::Approx(0.0f));
    CHECK(r.seconds == doctest::Approx(kAppleHapticMaxSeconds));
    CHECK(apple_rumble(1.0f, 1.0f, 0.0f, false, false).seconds == doctest::Approx(0.01f));
}
