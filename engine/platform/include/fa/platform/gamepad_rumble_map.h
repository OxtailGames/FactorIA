// How a rumble request (low and high strength, 0..1, and seconds) becomes the numbers each platform's API wants. Pure
// functions with no system calls, so every OS builds and unit-tests them (tests/rumble_map_tests.cpp), although only the
// matching backend uses each one: Linux evdev (gamepad_linux.cpp), Android vibrators (gamepad_android.cpp) and Apple
// CoreHaptics (gamepad_apple.mm).
#pragma once

#include <cstdint>

namespace fa {

// Linux force feedback (struct ff_effect of type FF_RUMBLE): two 16-bit magnitudes and a length in milliseconds.
struct EvdevRumble {
    std::uint16_t strong = 0;    // strong_magnitude: the heavy, low-frequency motor (`low`)
    std::uint16_t weak = 0;      // weak_magnitude: the light, high-frequency motor (`high`)
    std::uint16_t lengthMs = 0;  // replay.length; never 0, which some drivers read as "forever"
    bool clamped = false;        // `seconds` did not fit the 16-bit length (65.535 s): it was cut, the engine's stop ends it
};
// Strengths are clamped to 0..1 and scaled to 0..0xFFFF; the length is `seconds` rounded up to whole milliseconds, at
// least 1 and at most 0xFFFF.
EvdevRumble evdev_rumble(float low, float high, float seconds);

// Android vibrators (VibrationEffect.createOneShot(ms, amplitude)): an amplitude is 1..255, and 0 here means "that
// vibrator stays off" (createOneShot rejects 0).
struct AndroidRumble {
    int amplitude[2] = {0, 0};  // [0] the first vibrator, [1] the second (only with two vibrators)
    long long millis = 0;       // at least 1, at most kAndroidRumbleMaxMillis
};
constexpr long long kAndroidRumbleMaxMillis = 60 * 1000;
// One vibrator (`vibrators` 1): both motors combine into the stronger of the two, in [0]. Two or more: low on the first,
// high on the second.
AndroidRumble android_rumble(float low, float high, float seconds, int vibrators);

// Apple CoreHaptics: a pad has up to two handle engines (GCHapticsLocalityLeftHandle and RightHandle), or one default
// engine. A continuous haptic event has an intensity 0..1 and a duration in seconds (CoreHaptics allows 30 s at most).
struct AppleRumble {
    bool split = false;    // true: two engines, [left, right]; false: one engine, `left` holds the intensity
    float left = 0, right = 0;
    float seconds = 0;     // clamped to 0.01..kAppleHapticMaxSeconds
};
constexpr float kAppleHapticMaxSeconds = 30.0f;
// `haveLeft` and `haveRight`: the controller offers that handle's locality. With both, low goes to the left handle and
// high to the right; with fewer, a single engine plays the stronger of the two.
AppleRumble apple_rumble(float low, float high, float seconds, bool haveLeft, bool haveRight);

}  // namespace fa
